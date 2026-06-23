function adcObj = evaluateAdcModel(designVars, modelParams, spec)
%evaluateAdcModel System-level analytical model of a VCO-based ADC.
% Basline model which captures core trade-offs and acts as a starting point 
% to build complete models for specific designs
%
%   adcObj = evaluateAdcModel(designVars, modelParams, spec)
%
%   This function evaluates an analytical model of a VCO-based
%   ADC. It computes linearity, noise, bandwidth, power, and overall
%   performance metrics, and returns an Adc object encapsulating results.
%
%   INPUTS:
%       designVars  : Vector of ADC design variables
%           (1) fs        - Sampling frequency (Hz)
%           (2) kVco      - VCO gain (Hz/V)
%           (3) vinFs     - Input full-scale voltage (V)
%           (4) nDac      - Feedback DAC resolution (bits)
%
%       modelParams : Structure of ADC model parameters with fields :
%           (Control):
%               .variant               - Boolean. Uses variant model when true
%               .variantName           - Name of function which contains variant model. Example : 'VOLTA.model.variants.evaluateAdcModelA'
%           (System):
%               .loopOrder             - DSM Loop order (V1.0 supports only loopOrder=1)
%               .nef                   - Noise Efficiency Factor
%               .maxFoM                - Maximum FoM_S (used to scale objective in optimization) (dB)
%               .noiseFoldingEnable    - Enable noise folding model (1 = Enabled)
%               .fsRes                 - Number of points in (0,fs/2) linspace
%               .bwIterMethod          - Fixed nubmer of iterations (0) or until tolerance is met (1)
%
%           (Input):
%               .maxVinFs              - Maximum allowable input full-scale (V)
%               .inputFreq             - Input signal frequency (Hz)
%               .minOsr                - Minimum oversampling ratio
%
%           (Quantizer):
%               .nMp                   - Number of interleaved phases in phase quantizer
%
%           (SFDR): Fourier Transform of Volterra kernels (=power
%           series coefficients for memoryless system) of order :
%               .a1                    - Linear (First Order)
%               .a2                    - Second-order
%               .a3                    - Third-order 
%
%           (DAC):
%               .cdacUnit              - Unit DAC capacitance (F)
%               .sigmaC                - DAC unit element mismatch (%)
%               .maxVdd                - Maximum process supply voltage (V)
%               .cdacType              - 0 for Binary weighted and 1 for highly segmented DEM 
%
%           (Power):
%               .vddAfe                - Analog front-end supply voltage (V)
%               .vddDig                - Digital supply voltage (V)
%               .pvcoRef               - Reference VCO power consumption (W)
%               .kvcoRef               - Reference VCO gain (Hz/V)
%               .pdigRef               - Reference digital power consumption (W)
%               .fsRef                 - Reference sampling frequency (Hz)
%               .vddDigRef             - Reference digital supply voltage (V)
%
%       spec        : Structure of ADC performance specifications with fields :
%           Required fields:
%               .fom                   - Target Schreier Figure of Merit 
%               .sndr                  - Target Signal to Noise+Distortion Ratio (dB)
%               .power                 - Target Power (W)
%               .bw                    - Target Signal bandwidth (Hz)

%               .irnFloor              - Target Input-Referred Noise Floor (V/√Hz)
%               .vinFs                 - Target Input Full-Scale Voltage (V)
%
%           Optional fields:
%               .rin                   - Target Input Resistance (Ohms)
%               .bwLow                 - Target Lower Bandwidth Limit (Hz)
%
%   OUTPUT:
%       adcObj      : Object of class Adc containing performance and auxiliary metrics
% -------------------------------------------------------------------------
% Author         : Sumukh Nitundil
% Affiliation    : EEMS Group, University of California San Diego
% MATLAB Version : R2024a
% License        : GNU General Public License v3 (GPLv3)
% -------------------------------------------------------------------------

%% Dispatch to variant model if requested
if isfield(modelParams,'variant') && isequal(modelParams.variant, true)

    assert(isfield(modelParams, 'variantName'), ...
        'modelParams.variantName must be specified when variant is enabled.');
    
    fcnName = modelParams.variantName;
    
    % Verify function exists and is callable (package-safe)
    assert(~isempty(which(fcnName)), ...
        'Variant model "%s" not found or not on path.', fcnName);


    % Call variant model and exit
    % Assumes variant model function has same inputs and outputs
    adcObj = feval(fcnName, designVars, modelParams, spec);
    return
end
%% Unpack design variables
fs      = designVars(1);   % Sampling frequency (Hz)
kVco    = designVars(2);   % VCO gain (Hz/V)
vinFs   = designVars(3);   % Input full-scale voltage (V)
nDac    = designVars(4);   % DAC resolution (bits)

%% Input : Range, attenuation, resistance and bwLow
% Enforce max input limit
vinFs  = min(vinFs,  modelParams.maxVinFs);

% DAC full-scale must support the ADC input range
vdacFs = vinFs;

% Enforce max supply limit
vdacFs = min(vdacFs, modelParams.maxVdd);

% Differential input peak amplitude
vinPeak = vinFs / 2;

% Compute total CDAC capacitance 
cdacInt = 0;
if(modelParams.cdacType==1) % Highly Segmented Tree-DEM []
    cdacInt = 16 * 2^(nDac - 4);
    for k = 0:nDac-5
        cdacInt = cdacInt + 2 * 2^k;
    end
else                        % Binary weighted array
    for k = 0:nDac-1
        cdacInt = cdacInt + 2^k;
    end
end
cdacTotal = cdacInt * modelParams.cdacUnit;
%% SFDR : Tonal Non-linearity
% Feedback and feedforward gains
feedbackGain = vdacFs ./ 2.^nDac;          % DAC LSB gain
feedforwardGain = kVco / fs;             % VCO gain normalized by sampling
loopGain = feedforwardGain .* feedbackGain;

% Closed-loop magnitude response from input to error node
htMag = (2 * sin(pi * modelParams.inputFreq ./ fs)) ./ ...
        sqrt(loopGain.^2 .* cos(pi * modelParams.inputFreq ./ fs).^2 + ...
             (2 - loopGain).^2 .* sin(pi * modelParams.inputFreq ./ fs).^2);

% Peak amplitude at nonlinear block input
vinNlPeak = htMag .* vinPeak;

% Peak amplitudes at nonlinear block output for fundamental, 2nd order and
% 3rd order harmonics
voutNl1 = modelParams.a1 * vinNlPeak + ...
     (3/4) * modelParams.a3 * vinNlPeak.^3;
voutNl2 = (modelParams.a2 / 2) * vinNlPeak.^2;
voutNl3 = (modelParams.a3 / 4) * vinNlPeak.^3;

% Dominant spur
voutNlSpur = max(voutNl2, voutNl3);

% Spurious-free dynamic range (Linear)
sfdrLin = (voutNl1.^2) ./ (voutNlSpur.^2);
%% Quantizer : Phase-Domain quantization by edge counting
deltaPhi = 2*pi / modelParams.nMp;                 % Step size in phase domain
kPhi = 2*pi * kVco / fs;               % Phase sensitivity (rad/V)
deltaV = deltaPhi / kPhi;              % Equivalent quantizer (voltage) step size at VCO input 

pQuant = deltaV^2 / 12;                % Quantization noise power at VCO input

%% AFE Noise and ADC Bandwidth
% Balanced design assumption: SNR ≈ SFDR
snrLin = sfdrLin;

% In-band white noise power referred to input
pNoiseAfe = vinPeak.^2 ./ (2 * snrLin);

% White-noise and 1st-order shaped noise corner frequency bandwidth
fBw = fs .* nthroot(3 * pNoiseAfe ./ (2 * deltaV.^2 * pi^2), 3);
osr = fs ./ (2 * fBw);

% Enforce minimum OSR constraint
idx = osr < modelParams.minOsr;
osr(idx) = modelParams.minOsr;
fBw(idx) = fs ./ (2 * osr(idx));

%% ADC SQNR 
nAdc = log2(vdacFs / deltaV);
mAdc = 2.^nAdc;

sqnr = (3 * mAdc.^2 .* (2 * modelParams.loopOrder + 1) .* ...
        osr.^(2 * modelParams.loopOrder + 1)) ./ ...
        (2 * pi^(2 * modelParams.loopOrder));

sqnrdB = 10 * log10(sqnr);

% Remove noise shaping to estimate minimum DAC resolution
sqnrQuantizer = sqnrdB - 10*log10((12 * osr.^2) / pi^2);
nDacMin = (sqnrQuantizer - 1.76) / 6.02;

%% Noise Folding
fVec = linspace(0, fs/2, modelParams.fsRes);

% Quantization noise PSD at quantizer
sEq = pQuant / (fs/2);

% Quantization noise transfer-function from quantizer (to output) to error node
hQuant = 2 * feedbackGain * sin(pi * fVec / fs);

% Quantization noise PSD at input of non-linear block
sEqNl = sEq .* hQuant.^2;

% DAC mismatch error standard deviation
sigmaE = sqrt(feedbackGain * modelParams.sigmaC^2);
mDac = 2^nDac;
sigmaLsb = sqrt((mDac - 1)/3) * sigmaE;

% DAC mismatch power and PSD at input of non-linear block
pMismatch = sigmaLsb^2;
sMismatch = pMismatch / (fs/2);
ntf = 2 * sin(pi * fVec / fs);
sMismatchNl = sMismatch .* ntf.^2;

% Volterra-based noise folding
alpha2 = 2 * modelParams.a2^2 / (2*pi);
alpha3 = 6 * modelParams.a3^3 / (4*pi^2);

sEq2 = alpha2 * VOLTA.utilities.circularConvolvePsd(sEqNl, sEqNl, fs);
sEq3 = alpha3 * VOLTA.utilities.circularConvolvePsd( ...
        VOLTA.utilities.circularConvolvePsd(sEqNl, sEqNl, fs), sEqNl, fs);

sMis2 = alpha2 * VOLTA.utilities.circularConvolvePsd(sMismatchNl, sMismatchNl, fs);
sMis3 = alpha3 * VOLTA.utilities.circularConvolvePsd( ...
         VOLTA.utilities.circularConvolvePsd(sMismatchNl, sMismatchNl, fs), ...
         sMismatchNl, fs);

sNoiseNl = (sEq2 + sEq3 + sMis2 + sMis3);

%% Iterative bandwidth calculation
if strcmp(modelParams.bwIterMethod,'fixed') % Pre-defined number of iterations
    for k = 1:modelParams.bwIterations
        inBand = fVec <= fBw;
        if nnz(inBand) > 1
            pNoiseNl = trapz(fVec(inBand), sNoiseNl(inBand));
        else
            pNoiseNl = 0;
        end
    
        pNoiseNlIn = pNoiseNl * feedbackGain^2;
    
        if modelParams.noiseFoldingEnable
            pNoiseTotal = pNoiseAfe + pNoiseNlIn;
        else
            pNoiseTotal = pNoiseAfe;
        end
    
        fBw = fs .* nthroot(3 * pNoiseTotal ./ (2 * deltaV.^2 * pi^2), 3);
        osr = fs ./ (2 * fBw);
    
        idx = osr < modelParams.minOsr;
        osr(idx) = modelParams.minOsr;
        fBw(idx) = fs ./ (2 * osr(idx));

        sqnr = (3 * mAdc.^2 .* (2 * modelParams.loopOrder + 1) .* ...
        osr.^(2 * modelParams.loopOrder + 1)) ./ ...
        (2 * pi^(2 * modelParams.loopOrder));
        sqnrdB = 10 * log10(sqnr);
        % Remove noise shaping to estimate minimum DAC resolution
        sqnrQuantizer = sqnrdB - 10*log10((12 * osr.^2) / pi^2);
        nDacMin = (sqnrQuantizer - 1.76) / 6.02;
    end
else 
    % Iterate until percent change is less than input tolerance
    
    % Initialize previous bandwidth for convergence check
    fBwPrev = fBw;  
    bwIterDelta = Inf;  % initialize as large to enter the loop

    while abs(bwIterDelta) > modelParams.bwIterTol
        inBand = fVec <= fBw;
        if nnz(inBand) > 1
            pNoiseNl = trapz(fVec(inBand), sNoiseNl(inBand));
        else
            pNoiseNl = 0;
        end
    
        pNoiseNlIn = pNoiseNl * feedbackGain^2;
    
        if modelParams.noiseFoldingEnable
            pNoiseTotal = pNoiseAfe + pNoiseNlIn;
        else
            pNoiseTotal = pNoiseAfe;
        end
    
        % Update bandwidth
        fBw = fs .* nthroot(3 * pNoiseTotal ./ (2 * deltaV.^2 * pi^2), 3);
    
        % Update oversampling ratio
        osr = fs ./ (2 * fBw);
    
        % Enforce minimum OSR
        idx = osr < modelParams.minOsr;
        osr(idx) = modelParams.minOsr;
        fBw(idx) = fs ./ (2 * osr(idx));
    
        % Update SQNR for new fBw
        sqnr = (3 * mAdc.^2 .* (2 * modelParams.loopOrder + 1) .* ...
            osr.^(2 * modelParams.loopOrder + 1)) ./ ...
            (2 * pi^(2 * modelParams.loopOrder));
        sqnrdB = 10 * log10(sqnr);
        sqnrQuantizer = sqnrdB - 10*log10((12 * osr.^2) / pi^2);
        nDacMin = (sqnrQuantizer - 1.76) / 6.02;
    
        % --- Compute bandwidth iteration change as percentage ---
        bwIterDelta = 100 * (fBw - fBwPrev) / fBwPrev;  % percentage change
        fBwPrev = fBw;  % update previous value for next iteration
    end

end
%% Total Input referred noise and SNDR
irnFloor = sqrt(pNoiseTotal ./ fBw);
sndrLin = vinPeak^2 / pNoiseTotal;
sndrDb = 10 * log10(sndrLin);

%% Power Estimation
kb = 1.38e-23;

iAfe = modelParams.nef^2 * pi * 4 * kb * modelParams.T * modelParams.phiT .* ...
       fBw ./ (2 * pNoiseTotal);
pAfe = modelParams.vddAfe * iAfe;

pDac = cdacTotal .* vdacFs.^2 .* fs;
pVco = modelParams.pVcoRef * kVco / modelParams.kVcoRef;
pDig = modelParams.pDigRef * ...
       (modelParams.vddDig / modelParams.vddDigRef)^2 * ...
       (fs / modelParams.fsRef);

pTotal = pAfe + pDac + pVco + pDig;

%% Figure of Merit and object creation
fom = sndrDb + 10*log10(fBw ./ pTotal);

perf = struct( ...
    'FOM', fom, ...
    'SNDR', sndrDb, ...
    'P_TOT', pTotal, ...
    'BW', fBw, ...
    'IRN_FLOOR', irnFloor);

perfAux = struct( ...
    'P_AFE', pAfe, ...
    'P_DAC', pDac, ...
    'NDAC_MIN', nDacMin, ...
    'P_VCO', pVco, ...
    'P_DIG', pDig, ...
    'VDAC_FS', vdacFs);

adcObj = VOLTA.model.Adc(designVars, modelParams, perf, perfAux, spec);

end


