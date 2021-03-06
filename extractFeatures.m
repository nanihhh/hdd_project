function features = extractFeatures(wav,fs,opt)
%% Extract features from a song
% 1 - zcr
% 2 - specC mean
% 3 - specC var
% 4 - specR mean
% 5 - specR var
% 6 - specF mean
% 7 - specF var
% 8 - avg Loudness
% 9:13 - 5 MFCC means 
% 14:18 - 5 MFCC vars
% 19 - fpMax
% 20 - fpBass
% 21 - fpAggr
% 22 - fpDLF
% 23 - fpGrav
% 24 - fpFoc

    features = [];

    N = length(wav);

    % Zero crossing rate
    zcr = 0.5 * sum(abs(sign(wav(2:N) - sign(wav(1:(N-1))))))/(N*fs);
    features = [features; zcr];
    clear zcr;
    
    %% Spectral Analysis features

    % Get the raw mel cepstrum with a 92ms window
    analysisOpt = struct('segLength',1024',...
                    'shiftLength',1024',...
                    'method','raw');
    nMelBins = 36;
    [~, melS, powS] = mfcc(wav,fs,analysisOpt);

    % Spectral Centroid
    specC = (1:nMelBins)*melS ./ sum(melS,1);
    features = [features; mean(specC); var(specC)];
    clear specC;

    % Spectral Rolloff
    specR = zeros(size(melS,2),1);
    for t = 1:size(melS,2)
        i = find(cumsum(melS(:,t)) >= 0.85*sum(melS(:,t)),1);
        specR(t) = i;
    end
    features = [features; mean(specR); var(specR)];
    clear specR;

    % Spectral Flux
    % The mean of the spectral flux is similar to the "percusiveness"
    % defined by Pompak
    normMS = melS*diag(1./sum(melS,1));
    specF = sum( (normMS(:,2:length(melS)) ...
                    - normMS(:,1:(length(melS)-1))).^2, 1 );
    features = [features; mean(specF); var(specF)];
    clear specF;

    % Noisiness
    fmax = size(powS,1);
    noise = sum(sum(abs(powS(1:(fmax-1),:) - powS(2:fmax,:))));
    
    clear noise;

    % Average Loudness
    avgLoud = mean(melS(:));
    features = [features; avgLoud];

    %% Fluctuation patterns

    [fpMed,~] = flucPat(melS);
    clear melS;
    fp = reshape(fpMed, [12 30]);
    
    fpMax = max(fp(:));
    fpBass = sum(sum(fp(1:2,3:end)));
    fpAggr = sum(sum(fp(2:end,1:4)))/fpMax;
    fpDLF = sum(sum(fp(1:3,:)))/sum(sum(fp(9:end,:)));
    fpGrav = sum( fp*(1:size(fp,2))' )/sum(fp(:));
    fpFoc = mean(fp(:))/fpMax;

    %% MFCCs
    textureOpt = struct('segLength',11024',...
                    'shiftLength',11024/2',...
                    'method','dct',...
                    'numTerms',6);
    [melDCT, ~, ~] = mfcc(wav,fs,textureOpt);
    melDCT = melDCT(2:6,:);
    
    %% Construct the feature vector
    
    features = [features; mean(melDCT,2); var(melDCT,0,2); ...
                fpMax; fpBass; fpAggr; ...
                fpDLF; fpGrav; fpFoc];

end
