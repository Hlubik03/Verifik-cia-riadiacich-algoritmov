clc; clear; close all;

%% System
% Zakladne parametre systému
m1 = 2500;  % Hmotnosť karosérie vozidla (kg)
m2 = 320;   % Hmotnosť kolesa a zavesenia (kg)
k1 = 80000; % Tuhosť pružiny medzi karosériou a kolesom (N/m)
k2 = 500000; % Tuhosť pneumatiky (N/m)
b1 = 350;   % Tlmenie medzi karosériou a kolesom (Ns/m)
b2 = 15020; % Tlmenie pneumatiky (Ns/m)

% Prenosové funkcie systému odpruženia
n1 = [(m1 + m2) b2 k2]; 
d1 = [(m1 * m2) (m1*(b1+b2)) + (m2*b1) (m1*(k1+k2)) + (m2*k1) + (b1*b2) (b1*k2) + (b2*k1) k1*k2]; 
G1 = tf(n1, d1);  % pohyb karosérie

n2 = [-(m1*b2) -(m1*k2) 0 0]; 
G2 = tf(n2, d1);  % pohyb kolesa

% Prenosová funkcia pre silu
sila = tf(n2, n1);

% PID parametre
Kd = 208025;  
Kp = 832100; 
Ki = 624075;  

C = pid(Kp, Ki, Kd);  

% Odsimulovanie uzavretého systému so spätnou väzbou
sys_cl = sila * feedback(G1, C);

% Časová os simulácie
t = 0:0.05:5;

%% Verifikacia
% Vstupné poruchy (výmoly) od -0.1 do +0.1 s krokom 0.001
vymoly = -0.1:0.001:0.1;

% Nastavenie tolerancie pre reguláciu
tolerance = 0.0005;

% čas pre každý vymol
cas_regulacie_vsetky = zeros(size(vymoly));

% Maximálny čas regulácie
max_cas_regulacie = 0;
najhorsi_vymol = 0;

% Pre každý vymol čas regulácie
for i = 1:length(vymoly)
    % Definovanie vstupnej poruchy ako skok s aktuálnou hodnotou vymolu
    [y, t] = step(vymoly(i) * sys_cl, t);
    
    % Posledný čas, kedy je odozva mimo tolerančného intervalu
    index_regulacie = find(abs(y) > tolerance, 1, 'last');
    
    % Skontroluj
    if ~isempty(index_regulacie)
        cas_regulacie = t(index_regulacie);
        cas_regulacie_vsetky(i) = cas_regulacie;
        
        % Aktualizácia najdlhšieho času 
        if cas_regulacie > max_cas_regulacie
            max_cas_regulacie = cas_regulacie;
            najhorsi_vymol = vymoly(i);
        end
    else
        cas_regulacie_vsetky(i) = NaN; % Ak sa systém ustálil okamžite, nastavíme NaN
    end
end

% Výsledok
if max_cas_regulacie > 0
    fprintf('Najdlhší čas regulácie je %.4f s pre vymol %.4f.\n', max_cas_regulacie, najhorsi_vymol);
else
    disp('Systém sa ustálil v rámci požadovanej tolerancie pre všetky vymoly.');
end

% Regulácie pre každý vymol
figure;
plot(vymoly,cas_regulacie_vsetky, 'bo-', 'MarkerFaceColor', 'b');
xlabel('Vymol');
ylabel('Čas regulácie (s)');
title('Čas regulácie pre jednotlivé vymoly');
grid on;

% Najhorší vymol
figure;
[y_najhorsi, t] = step(najhorsi_vymol * sys_cl, t);
plot(t, y_najhorsi, 'b-', 'LineWidth', 1.5);
hold on;
yline(tolerance, 'r--', 'Tolerancia +-0.0005');
yline(-tolerance, 'r--');
xlabel('Cas (s)');
ylabel('Odozva systému');
title(sprintf('Odozva systému pre vymol %.4f s najdlhším časom regulácie', najhorsi_vymol));
grid on;
