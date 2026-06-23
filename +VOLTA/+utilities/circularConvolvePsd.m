function [Sout, f_out] = circularConvolvePsd(S1, S2, fs)
%circularConvolvePsd Circular convolution of one-sided PSDs
%
%   [Sout, f_out] = circularConvolvePsd(S1, S2, fs)
%
%   Circularly convolve two one-sided power spectral densities (PSDs)
%   defined over the frequency range (0,fs/2) for discrete-time signals.
%   The operation accounts for aliasing and spectral folding due to
%   sampling.
%
%   Inputs:
%       S1, S2 : One-sided PSD vectors (0 .. fs/2), same length, row or column
%       fs     : Sampling frequency (Hz)
%
%   Outputs:
%       Sout   : One-sided circular convolution result (0 .. fs/2), same orientation as S1
%       f_out  : Frequency vector corresponding to Sout (Hz), same orientation as S1
%
% Notes:
%   - The input PSDs are mirrored to form two-sided spectra spanning −fs/2 .. fs/2
%   - Circular convolution is performed over one period.
%   - The result is folded back to one-sided form.
%   - Scaling by df preserves physical units (e.g., V^2/Hz).

    % --- Input checks ---
    if nargin < 3
        error('Usage: circularConvolvePsd(S1, S2, fs)');
    end
    if length(S1) ~= length(S2)
        error('S1 and S2 must have the same length');
    end

    % --- Detect input orientation ---
    isRow = isrow(S1);
    S1 = S1(:);  % convert to column for processing
    S2 = S2(:);

    N1 = length(S1);
    df = (fs/2) / (N1 - 1);

    % --- Mirror to obtain two-sided PSDs (period fs) ---
    S1_2sided = [S1; flipud(S1(2:end-1))];
    S2_2sided = [S2; flipud(S2(2:end-1))];
    N2 = length(S1_2sided);

    % --- Circular convolution over one period ---
    S_conv_2sided = cconv(S1_2sided, S2_2sided, N2) * df;

    % --- Fold back to one-sided form ---
    Sout = zeros(N1, 1);
    Sout(1) = S_conv_2sided(1);                          % DC
    Sout(2:N1-1) = S_conv_2sided(2:N1-1) + ...
                   S_conv_2sided(end-(N1-2):end-1);
    Sout(N1) = S_conv_2sided(N1);                        % Nyquist

    % --- Frequency vector (0 .. fs/2) ---
    f_out = linspace(0, fs/2, N1).';

    % --- Restore original orientation ---
    if isRow
        Sout  = Sout.';
        f_out = f_out.';
    end
end
