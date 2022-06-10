function [ aquired, pr_delay, phase_delay ] = SV_CA_doppler_search( srx, L, doppler_range, resolution)
%SV_CA_doppler_search s phase/code aquisition of CA code.
%
%SV_CA_doppler_search.m should be used if looking for precise results
%
%INPUT:
%srx= received signal
%L = samples per C/A code bit in srx
%doppler_range = range to scan (tipically 10k)
%resolution = frequency scan step size
%OUTPUT
%aquired = SVs found
%pr_delay = time delay in samples (for positioning) (multiply by TM for seconds)
%phase_delay = frequency shift in samples (multiply by resolution for hz)

base_clock = 10.23e6;
search_res = resolution;
Lchip = 2 ^ 10 - 1;
f_chip = base_clock/10;
Tchip = Lchip / f_chip;
fm = L * f_chip;
Tm = 1/fm;
t = Tm:Tm:Tchip;

f_steps = -doppler_range:search_res:doppler_range;
n_steps = length(f_steps);
modulator = exp(1i * 2* pi * f_steps' * t);

modulator_mat = real(permute(repmat(modulator, 1, 1, 32),[3 1 2]));
rep_CA = permute(repmat(CA_gen(L), 1, 1, n_steps), [1 3 2]);

test_sCA =  rep_CA .* modulator_mat; % generamos codigos CA de todos los satelites
%check vissible SV xcorr search
max_SV = 32;
checkSV = 1:max_SV * n_steps; %checks all possible SV
corrsearch = zeros(max_SV, n_steps, 2 * L * 1023 - 1);
for i = checkSV
    a = mod(i - 1, max_SV) + 1;
    b = ceil(i / max_SV);
    corrsearch(a, b, :) = xcorr(squeeze(srx), squeeze(test_sCA(a, b, :)));
end


% detect_lim = L * 1023 * 2 / 5 - 1; % lowered threshold because of noise;
detect_lim = 1.4e4;
[peak, rdelay_samples] = max(corrsearch, [], 3);
%
[peak, f_offset] = max(peak, [], 2);
indices = 1:size(rdelay_samples,2):numel(rdelay_samples);
rdelay_samples_tmp = rdelay_samples';
rdelay_samples_tmp=rdelay_samples_tmp(:);
rdelay_samples = rdelay_samples_tmp(indices' + f_offset - 1);
%
aquired = checkSV(peak >= detect_lim);%detected SV index
if (length(aquired) < 4)
    fprintf('not enough SV detected, acquisition impossible\n')
end
pr_delay = rdelay_samples(peak >= detect_lim);
phase_delay = f_offset(peak >= detect_lim);

    
end

