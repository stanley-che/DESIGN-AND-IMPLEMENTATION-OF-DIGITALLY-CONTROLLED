%% ==== 用 DZP 產生 3p3z LUT（跟原來 q 法一樣的流程） ====
clc;
format long;
Ts = 2e-6;
z  = tf('z',Ts);   % 離散時間 z

% ---- 你ee的補償器 (3 zero, 3 pole) ----
Z = [-1 0.994599 0.836762];
P = [ 1 -0.403087 -0.0858861];
Kc = 12;

C = zpk(Z,P,Kc,Ts);      % C(z) from DZP
[Gcdnum, Gcdden] = tfdata(C,'v');   % Gcdnum 有 4 個係數

% ===== Word-length selection（完全沿用原本想法，只是多一個係數） =====
e_n_max = 4;
e_n_min = -4;

Nia = ceil(log2(1+abs(2*Gcdnum(1)*e_n_max)));
Nib = ceil(log2(1+abs(2*Gcdnum(2)*e_n_max)));
Nic = ceil(log2(1+abs(2*Gcdnum(3)*e_n_max)));
Nid = ceil(log2(1+abs(2*Gcdnum(4)*e_n_max)));

Nd  = ceil(abs(log2(1/(Gcdnum(1)+Gcdnum(2)+Gcdnum(3)+Gcdnum(4)))));

Na = Nia + Nd + 1;
Nb = Nib + Nd + 1;
Nc = Nic + Nd + 1;
Nd4= Nid + Nd + 1;

Nbit = max([Na Nb Nc Nd4])

% ===== quantization（跟原來一樣用 Vq） =====
Vq = 0.0078125;   % 1/128

aq = quantize_coeff(Gcdnum(1), Vq, Nbit);
bq = quantize_coeff(Gcdnum(2), Vq, Nbit);
cq = quantize_coeff(Gcdnum(3), Vq, Nbit);
dq = quantize_coeff(Gcdnum(4), Vq, Nbit);   % 第四個係數

% ===== LUT 數值（對應 err = -4:4） =====
Code = e_n_min:e_n_max;

ae_product = aq*Code.*Vq*(2^Nbit);
be_product = bq*Code.*Vq*(2^Nbit);
ce_product = cq*Code.*Vq*(2^Nbit);
de_product = dq*Code.*Vq*(2^Nbit);

a_table = num2bin(quantizer([Nbit+2,0]), ae_product)
b_table = num2bin(quantizer([Nbit+2,0]), be_product)
c_table = num2bin(quantizer([Nbit+2,0]), ce_product)
d_table = num2bin(quantizer([Nbit+2,0]), de_product)   % ★ 新的 d LUT

% ===== limiter duty_max 轉二進位（跟原來完全一樣） =====
duty_max = 0.95;
kd   = dec2bin(duty_max*(2^(Nbit+1)));
Ka   = bin2dec(kd) / (2^(Nbit+1));
Kal  = Ka*(2^(Nbit+1));
duty_bin = num2bin(quantizer([Nbit+2,0]), Kal)

% ---- 小工具：係數量化 ----
function q = quantize_coeff(c, Vq, Nbit)
    D  = round(abs(c*Vq)*(2^Nbit));
    Aq = sign(c) * D/(2^Nbit);
    q  = Aq / Vq;
end
