close all; clear; clc;
%% Type-III compensator (3 poles, 2 zeros)  — transfer function + Bode
% Component values from your schematic
R1 = 3132.63;
R2 = 100;
R3 = 100;
C1 = 1.08e-8;
C2 = 3.03e-7;
C3 = 6.62e-9;

K  = 15.548;        % 前級增益方塊（你的 K）

% ------- Symbolic s and TF -------
s = tf('s');

% Zeros and poles (rad/s)
wz1 = 1/(R2*C2);
wz2 = 1/((R1+R3)*C3);

wpI = 0;                               % integrator at origin (1/s)
wp1 = 1/(R3*C3);
wp2 = (C1 + C2)/(R2*C1*C2);

% Type-III compensator gain (per your formula)
% Gc(s) = K * (R1+R3)/(R1*R3*C1) * (s + 1/(R2*C2)) * (s + 1/((R1+R3)*C3))
%         ---------------------------------------------------------------
%                 s * (s + (C1+C2)/(R2*C1*C2)) * (s + 1/(R3*C3))
Gc = K * ((R1+R3)/(R1*R3*C1)) * ...
     (s + 1/(R2*C2)) * (s + 1/((R1+R3)*C3)) / ...
     ( s * (s + (C1+C2)/(R2*C1*C2)) * (s + 1/(R3*C3)) );

% ------- Print pole/zero locations (Hz) -------
toHz = @(w) w/(2*pi);
fprintf('Zeros (Hz):  wz1=%.1f Hz, wz2=%.1f Hz\n', toHz(wz1), toHz(wz2));
fprintf('Poles (Hz):  wpI=0 (integrator),  wp2=%.1f Hz,  wp1=%.1f Hz\n', ...
        toHz(wp2), toHz(wp1));

% ------- Bode settings -------
fs  = 500e3;                  % 你的 PWM switching freq
fmin = 1e2;                   % 100 Hz 起掃
fmax = min(2e5, fs/2*0.8);    % 避免超過 fs/2，留 20% margin
w    = 2*pi*logspace(log10(fmin), log10(fmax), 400);

opts = bodeoptions;
opts.Grid = 'on';
opts.XLim = [2*pi*fmin, 2*pi*fmax];
opts.MagUnits = 'dB';
opts.PhaseWrapping = 'on';

figure; bodeplot(Gc, w, opts); hold on;
[GM, PM, wcg, wcp] = margin(Gc);
margin(Gc);                   % 疊上增益/相位裕度標記
title('Type-III Compensator  G_c(s)');

% 可選：顯示交越頻率與裕度
fprintf('Gain margin: %.2f dB at %.1f Hz\n', 20*log10(GM), toHz(wcg));
fprintf('Phase margin: %.1f deg at %.1f Hz\n', PM, toHz(wcp));
%% ===== 把 TF 係數、零極點、Bode 指標通通列出 =====
% 1) 取出係數（降冪）
[num, den] = tfdata(Gc, 'v');   % row vectors

% 2) 零、極點、增益
[z, p, k] = zpkdata(Gc, 'v');

% 3) 交越頻率、增益/相位裕度
[GM, PM, wgc, wpc] = margin(Gc);

% 4) 顯示（含科學記號 & Hz）
fprintf('\n--- Type-III compensator parameters ---\n');
fprintf('Numerator coefficients (降冪):\n  %s\n', mat2str(num, 6));
fprintf('Denominator coefficients (降冪):\n  %s\n', mat2str(den, 6));

fmtC = @(x) sprintf('%.6g', x);      % 科學記號
fmtHz= @(w) sprintf('%.3f Hz', w/(2*pi));

% 零點/極點（以 Hz 顯示）
if ~isempty(z)
    fprintf('Zeros:\n');
    for i=1:numel(z)
        fprintf('  z%-2d = %-12s  (%s)\n', i, fmtC(z(i)), fmtHz(abs(z(i))));
    end
else
    fprintf('Zeros:  (none)\n');
end

if ~isempty(p)
    fprintf('Poles:\n');
    for i=1:numel(p)
        fprintf('  p%-2d = %-12s  (%s)\n', i, fmtC(p(i)), fmtHz(abs(p(i))));
    end
else
    fprintf('Poles:  (none)\n');
end

% DC 增益（如有積分極會趨近無限，僅做提示）
try
    dcgain_val = dcgain(Gc);
    fprintf('DC gain: %g\n', dcgain_val);
catch
    fprintf('DC gain: undefined (integrator present)\n');
end

% 裕度與交越
if isfinite(GM), GMdB = 20*log10(GM); else, GMdB = Inf; end
fprintf('Gain margin : %s dB  @ %s\n', fmtC(GMdB), fmtHz(wgc));
fprintf('Phase margin: %.2f deg @ %s\n', PM, fmtHz(wpc));

% 5)（可選）把係數自動灌進 Simulink 的 Transfer Fcn block
%    把下行 blockPath 換成你的方塊路徑（或右鍵 Copy Block Path 貼上）
% blockPath = '你的模型名/Standalone_transfer_close_loop';
% set_param(blockPath, 'Numerator',   mat2str(num, 6), ...
%                        'Denominator', mat2str(den, 6));

