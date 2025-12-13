%% buck_pid_q_design.m  —  q法自動設計 PID（類比→離散），直接給 DZP 參數
clear; clc;
s = tf('s');

%% ===== 規格/電路 =====
Vg=9; Vo=1.5;
fs=500e3; Ts=1/fs;                 % 500 kHz
L=10e-6; rL=20e-3;
C=22e-6; rC=20e-3;
Iload=0.5;                         % 0.5 A 負載
Rload=Vo/Iload;

% 量測/調變
Hsense = 1;                        % 先設 1
Vtri   = 3;                        % DPWM 三角波峰值
Kpwm   = 1/Vtri;

% 迴路延遲（不含 D*Ts）
t_conv=420e-9; t_cal=10e-9; t_g=55e-9+10e-9;
td = t_conv + t_cal + t_g;         % 約 0.495 us

%% ===== 被控對象（含延遲）的 control-to-output =====
Plant = Hsense*Kpwm * buck_cto(Vg,L,rL,C,rC,Rload,td);

% 一些參考
w0 = 1/sqrt(L*C);
f0 = w0/2/pi;
fESR = 1/(2*pi*rC*C);
fprintf('[PLANT] R=%.3fΩ, f0=%.1f kHz, fESR=%.1f kHz, Ts=%.0f ns, td=%.0f ns\n',...
        Rload, f0/1e3, fESR/1e3, Ts*1e9, td*1e9);

%% ===== 設計目標 =====
fc   = fs/10;                 % 交越頻率（課本建議）
PMtar= 60;                    % 目標相位裕度
PMguard = 4;                 % 安全餘量（避免量化/延遲造成流失）
wc = 2*pi*fc;

%% ===== 依投影片 q 法配置 (單一 lead) =====
% 需要補的相位 = 目標PM - (180 + Plant相位) + guard
Pjw = squeeze(freqresp(Plant, wc));
phiP = rad2deg(angle(Pjw));                  % 植物在 wc 的相位 (≈負角度)
phi_need = PMtar - (180 + phiP) + PMguard;   % 該補多少

% 限制可用的補償量（單一 lead 約 0~70deg 可行）
phi_need = max(0, min(phi_need, 70));

q = deg2rad(phi_need);                       % 以弧度帶入公式
fz = fc*sqrt((1 - sin(q))/(1 + sin(q)));     % 課本頁16
fp = fc*sqrt((1 + sin(q))/(1 - sin(q)));

% 低頻積分零點、HF 極點（頁17建議 fp2=fESR 或 0.3fs）
fL  = fc/120;                                 % 穩定與靜態誤差
fp2 = min(fESR, 500*fs);

% 類比補償器（PID + 1個 lead + HF 極點）
Gc0 = (1 + (2*pi*fL)/s) * (1 + s/(2*pi*fz)) / (1 + s/(2*pi*fp)) * 1/(1 + s/(2*pi*fp2));

% 求 Gcm 使 |Gc(jwc)P(jwc)|=1
mag_at_wc = abs(squeeze(freqresp(Gc0*Plant, wc)));
Gcm = 1/mag_at_wc;
Gc_s = minreal(Gcm*Gc0);

% 類比開迴路裕度
[~, PMa, ~, Wcpa] = margin(Gc_s*Plant);

%% ===== 離散化（Tustin + 預失真） =====
opt = c2dOptions('Method','tustin','PrewarpFrequency', wc);
Gc_d = c2d(Gc_s, Ts, opt);

% 離散開迴路（把 plant 也離散化只做趨勢檢查）
Lz = Gc_d * c2d(Plant, Ts, 'tustin');
[GMd, PMd, Wcgd, Wcpd] = margin(Lz);

%% ===== 輸出給 Discrete Zero-Pole =====
[numd, dend] = tfdata(Gc_d,'v');
numd = numd/dend(1);  dend = dend/dend(1);   % 使分母首項=1
[z, p, k] = tf2zp(numd, dend);

fprintf('\n=== Design @ fc=%.1f kHz, Vtri=%.1f V ===\n', fc/1e3, Vtri);
fprintf('Needed phase boost(q)=%.1f deg  ->  fz=%.1f kHz, fp=%.1f kHz\n', phi_need, fz/1e3, fp/1e3);
fprintf('fL=%.1f kHz, fp2=%.1f kHz,  Gcm=%.3g\n', fL/1e3, fp2/1e3, Gcm);
fprintf('Analog PM≈%.1f deg @ %.1f kHz\n', PMa, Wcpa/2/pi/1e3);
fprintf('Discrete PM≈%.1f deg @ %.1f kHz, GM=%.2f @ %.1f kHz\n', PMd, Wcpd/2/pi/1e3, GMd, Wcgd/2/pi/1e3);
fprintf('DZP: Zeros=%s\n', mat2str(z.',6));
fprintf('     Poles=%s\n',  mat2str(p.',6));
fprintf('     Gain =%.6g\n', k);
fprintf('     Ts   =%.3g s\n\n', Ts);

%% (可選) 繪圖檢查
% figure; bode(Gc_s*Plant); grid on; title('Analog Open-Loop');
% figure; bode(Lz); grid on; title('Discrete Open-Loop');

%% ===== 推薦的 Simulink/PLECS 參數 =====
Vq_adc = 7.8125e-3;            % 8-bit ±1V 假設
fprintf('--- Simulink blocks ---\n');
fprintf('ZOH sample time  : Ts = %.0f ns\n', Ts*1e9);
fprintf('ADC Quantizer    : interval = %.6f V ; Saturation = [%.6f, %.6f] V (±4 LSB)\n',...
        Vq_adc, -4*Vq_adc, 4*Vq_adc);
fprintf('DPWM Quantizer   : interval = 1/512 ; Duty saturation ≈ [0.05, 0.95]\n');

%% ==== Local function: buck Cto (含延遲) ====
function Gvd = buck_cto(Vg,L,rL,C,rC,R,t_d)
  s = tf('s');
  w0 = 1/sqrt(L*C);
  wz = 1/(rC*C);
  Q  = (1/w0) * 1/( L/(R+rL) + C*( rC + rL*R/(rL+R) ) );
  Gvd = Vg * (1 + s/wz) / (1 + s/(Q*w0) + (s/w0)^2) * exp(-s*t_d);
end
