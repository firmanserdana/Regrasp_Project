function [stim_string,safe,cmdDelay,cmdTotDuration] = make_stim_string_vMultiChs(mode,stim_params,stim_params_name,safeLimit,stimChsID,amp_step_size)

safe = 1;               % flag for stim SAFE = below safety limits

% Components of stim string
elec_string = 'Elect='; % electrode
TL_string = 'TL=';      % train length [ms]
freq_string = 'Freq=';  % frequency [Hz]
PW_string = 'Dur=';     % pulse-width [ms]
amp_string = 'Amp=';    % amplitude [steps]
TD_string = 'TD=';      % train delay [ms]
FS_string = 'FS=';      % fast settle [ms]
PL_string = 'PL=';      % polarity (1 = cathodic-first, 0 = anodic-first)

% Set stim parameters
stim_string = {};
cmdDelay = [];

switch mode

    case 'SinglePulse'

        elec = stim_params(:,contains(stim_params_name,'Ch'));
        amp = stim_params(:,contains(stim_params_name,'Amp'));      % [µA]
        amp_steps = floor(amp / amp_step_size);                     % [steps]
        PW = stim_params(:,contains(stim_params_name,'PW'))*1e-3;   % [ms]
        freq = 1 * ones(size(elec));                                % [Hz]
        TL = 1000 * ones(size(elec));                               % [ms]
        TD = zeros(size(elec));                                     % [ms]
        FS = zeros(size(elec));
        PL = stim_params(:,contains(stim_params_name,'cathodic'));

        if ~isempty(find(amp.*PW*1e3 > safeLimit))
            safe = 0;
        end

        stim_string{1} = [elec_string cstr(stimChsID(elec)) ',;' TL_string cstr(TL) ',;' ...
            freq_string cstr(freq) ',;' PW_string cstr(PW) ',;' ...
            amp_string cstr(amp_steps) ',;' TD_string cstr(TD) ',;' ...
            FS_string cstr(FS) ',;' PL_string cstr(PL) ',;'];

        cmdDelay = 0;

    case 'SingleBurst'

        elec = stim_params(:,contains(stim_params_name,'Ch'));
        amp = stim_params(:,contains(stim_params_name,'Amp'));      % [µA]
        amp_steps = floor(amp / amp_step_size);                     % [steps]
        PW = stim_params(:,contains(stim_params_name,'PW'))*1e-3;   % [ms]
        freq = stim_params(:,contains(stim_params_name,'Freq'));    % [Hz]
        TL = stim_params(:,contains(stim_params_name,'Dur'));       % [ms]
        TD = zeros(size(elec));                                     % [ms]
        FS = zeros(size(elec));
        PL = stim_params(:,contains(stim_params_name,'cathodic'));

        cmdDelay = stim_params(:,contains(stim_params_name,'Delay'))*1e-3; % [s]

        % Sort the commands depending on the burst delay
        [~,idxSort] = sort(cmdDelay);
        elec = elec(idxSort);
        amp = amp(idxSort);
        amp_steps = amp_steps(idxSort);
        PW = PW(idxSort);
        freq = freq(idxSort);
        TL = TL(idxSort);
        TD = TD(idxSort);
        FS = FS(idxSort);
        PL = PL(idxSort);
        cmdDelay = cmdDelay(idxSort);
        cmdDelay = [cmdDelay(1) ; diff(cmdDelay)];

        % Make the stim string
        for iE = 1:length(elec)

            if amp(iE)*PW(iE)*1e3 > safeLimit
                safe = 0;
                break;
            end

            stim_string{iE} = [elec_string num2str(stimChsID(elec(iE))) ',;' TL_string num2str(TL(iE)) ',;' ...
                freq_string num2str(freq(iE)) ',;' PW_string num2str(PW(iE)) ',;' ...
                amp_string num2str(amp_steps(iE)) ',;' TD_string num2str(TD(iE)) ',;' ...
                FS_string num2str(FS(iE)) ',;' PL_string num2str(PL(iE)) ',;'];
        end

    case 'RC'

        elec = stim_params(:,contains(stim_params_name,'Ch'));
        amp_min = stim_params(:,contains(stim_params_name,'min amp'));  % [uA]
        amp_max = stim_params(:,contains(stim_params_name,'max amp'));  % [uA]
        amp_incr = stim_params(:,contains(stim_params_name,'step'));    % [uA]
        n_incr = floor((amp_max(1)-amp_min(1))/amp_incr(1)) + 1;
        reps = stim_params(:,contains(stim_params_name,'reps'));
        PW = stim_params(:,contains(stim_params_name,'PW'))*1e-3;       % [ms]
        freq = stim_params(:,contains(stim_params_name,'Freq'));        % [Hz]
        TL = reps./freq*1e3;                                            % [ms]
        TD = zeros(size(elec));                                         % [ms]
        FS = zeros(size(elec));
        PL = stim_params(:,contains(stim_params_name,'cathodic'));

        for iA = 1:n_incr

            amp = amp_min + (iA-1)*amp_incr;                            % [uA]
            amp_steps = floor(amp / amp_step_size);                     % [steps]

            if ~isempty(find(amp.*PW*1e3 > safeLimit))
                safe = 0;
                break;
            end

            stim_string{iA} = [elec_string cstr(stimChsID(elec)) ',;' TL_string cstr(TL) ',;' ...
                freq_string cstr(freq) ',;' PW_string cstr(PW) ',;' ...
                amp_string cstr(amp_steps) ',;' TD_string cstr(TD) ',;' ...
                FS_string cstr(FS) ',;' PL_string cstr(PL) ',;'];

            if iA==1
                cmdDelay(iA) = 0;                                       % [s]
            else
                cmdDelay(iA) = TL(1)*1e-3 + 1/freq(1);                  % [s]
            end
        end

    case 'AMBursts'

        elec = stim_params(:,contains(stim_params_name,'Ch'));
        amp_min = stim_params(:,contains(stim_params_name,'min amp'));  % [uA]
        amp_max = stim_params(:,contains(stim_params_name,'max amp'));  % [uA]
        amp_incr = stim_params(:,contains(stim_params_name,'step'));    % [uA]
        n_incr = floor((amp_max(1)-amp_min(1))/amp_incr(1)) + 1;
        reps = stim_params(:,contains(stim_params_name,'reps'));
        PW = stim_params(:,contains(stim_params_name,'PW'))*1e-3;       % [ms]
        freq = stim_params(:,contains(stim_params_name,'Freq'));        % [Hz]
        TL = stim_params(:,contains(stim_params_name,'Dur'));           % [ms]
        IBI = stim_params(:,contains(stim_params_name,'IBI'));          % [ms]
        TD = zeros(size(elec));
        FS = zeros(size(elec));
        PL = stim_params(:,contains(stim_params_name,'cathodic'));

        for iA = 1:n_incr

            amp = amp_min + (iA-1)*amp_incr;                            % [uA]
            amp_steps = floor(amp / amp_step_size);                     % [steps]

            if ~isempty(find(amp.*PW*1e3 > safeLimit))
                safe = 0;
                break;
            end

            for iR = 1:reps(1)

                stim_string{(iA-1)*reps(1)+iR} = [elec_string cstr(stimChsID(elec)) ',;' TL_string cstr(TL) ',;' ...
                    freq_string cstr(freq) ',;' PW_string cstr(PW) ',;' ...
                    amp_string cstr(amp_steps) ',;' TD_string cstr(TD) ',;' ...
                    FS_string cstr(FS) ',;' PL_string cstr(PL) ',;'];

                if (iA-1)*reps(1)+iR==1
                    cmdDelay((iA-1)*reps(1)+iR) = 0;                       % [s]
                else
                    cmdDelay((iA-1)*reps(1)+iR) = (TL(1)+IBI(1))*1e-3;     % [s]
                end
            end
        end

    case 'FMBursts'

        elec = stim_params(:,contains(stim_params_name,'Ch'));
        amp = stim_params(:,contains(stim_params_name,'Amp'));          % [uA]
        amp_steps = floor(amp / amp_step_size);                         % [steps]
        PW = stim_params(:,contains(stim_params_name,'PW'))*1e-3;       % [ms]
        freq_min = stim_params(:,contains(stim_params_name,'min freq'));% [Hz]
        freq_max = stim_params(:,contains(stim_params_name,'max freq'));% [Hz]
        freq_incr = stim_params(:,contains(stim_params_name,'step'));   % [Hz]
        n_incr = floor((freq_max-freq_min)/freq_incr) + 1;
        reps = stim_params(:,contains(stim_params_name,'reps'));
        TL = stim_params(:,contains(stim_params_name,'Dur'));           % [ms]
        IBI = stim_params(:,contains(stim_params_name,'IBI'));          % [ms]
        TD = zeros(size(elec));
        FS = zeros(size(elec));
        PL = stim_params(:,contains(stim_params_name,'cathodic'));
        cmdDelay = (TL+IBI)*1e-3;                                       % [s]

        if ~isempty(find(amp.*PW*1e3 > safeLimit))
            safe = 0;
        end

        for iF = 1:n_incr
            freq = freq_min + (iF-1)*freq_incr;             % [uA]

            for iR = 1:reps(1)

                stim_string{(iF-1)*reps(1)+iR} = [elec_string cstr(stimChsID(elec)) ',;' TL_string cstr(TL) ',;' ...
                    freq_string cstr(freq) ',;' PW_string cstr(PW) ',;' ...
                    amp_string cstr(amp_steps) ',;' TD_string cstr(TD) ',;' ...
                    FS_string cstr(FS) ',;' PL_string cstr(PL) ',;'];

                if (iF-1)*reps(1)+iR==1
                    cmdDelay((iF-1)*reps(1)+iR) = 0;                       % [s]
                else
                    cmdDelay((iF-1)*reps(1)+iR) = (TL(1)+IBI(1))*1e-3;     % [s]
                end
            end
        end

    case 'Tonic'

        elec = stim_params(:,contains(stim_params_name,'Ch'));
        amp = stim_params(:,contains(stim_params_name,'Amp'));          % [µA]
        amp_steps = floor(amp / amp_step_size);                         % [steps]
        PW = stim_params(:,contains(stim_params_name,'PW'))*1e-3;       % [ms]
        freq = stim_params(:,contains(stim_params_name,'Freq'));        % [Hz]
        TL = stim_params(:,contains(stim_params_name,'Dur'))*1e3;       % [ms]
        TD = zeros(size(elec));                                         % [ms]
        FS = zeros(size(elec));
        PL = stim_params(:,contains(stim_params_name,'cathodic'));

        if ~isempty(find(amp.*PW*1e3 > safeLimit))
            safe = 0;
        end

        stim_string{1} = [elec_string cstr(stimChsID(elec)) ',;' TL_string cstr(TL) ',;' ...
            freq_string cstr(freq) ',;' PW_string cstr(PW) ',;' ...
            amp_string cstr(amp_steps) ',;' TD_string cstr(TD) ',;' ...
            FS_string cstr(FS) ',;' PL_string cstr(PL) ',;'];

        cmdDelay = 0;

    case 'AMSine'

        elec = stim_params(:,contains(stim_params_name,'Ch'));
        amp_min = stim_params(:,contains(stim_params_name,'min amp'));      % [uA]
        amp_max = stim_params(:,contains(stim_params_name,'max amp'));      % [uA]
        PW = stim_params(:,contains(stim_params_name,'PW'))*1e-3;           % [ms]
        freq = stim_params(:,contains(stim_params_name,'Freq'));            % [Hz]
        sine_period = stim_params(:,contains(stim_params_name,'period'));   % [s]
        Dur = stim_params(:,contains(stim_params_name,'Dur'));              % [s]
        TL = 1.5 ./freq  .* ones(size(elec)) * 1000;                        % [ms]
        TD = zeros(size(elec));                                             % [ms]
        FS = zeros(size(elec));
        PL = stim_params(:,contains(stim_params_name,'cathodic'));

        % Build the sine waves
        dt = 1/min(freq); % seconds per sample
        t = (0:dt:Dur); % seconds

        amp_wave = [];

        for iE = 1:length(elec)
            F = 1/sine_period(iE); % Sine wave frequency (hertz)
            amp_wave(iE,:) = (amp_max(iE)+amp_min(iE))/2 + (amp_max(iE)-amp_min(iE))/2 .* sin(2*pi*F*t);
        end

        % create the stim command
        for iA = 1:size(amp_wave,2)

            amp = amp_wave(:,iA);                           % [uA]
            amp_steps = floor(amp / amp_step_size);         % [steps]

            if ~isempty(find(amp.*PW*1e3 > safeLimit))
                safe = 0;
                break;
            end

            stim_string{iA} = [elec_string cstr(stimChsID(elec)) ',;' TL_string cstr(TL) ',;' ...
                freq_string cstr(freq) ',;' PW_string cstr(PW) ',;' ...
                amp_string cstr(amp_steps) ',;' TD_string cstr(TD) ',;' ...
                FS_string cstr(FS) ',;' PL_string cstr(PL) ',;'];

            if iA==1
                cmdDelay(iA) = 0;                                       % [s]
            else
                cmdDelay(iA) = dt;                                      % [s]
            end
        end
end

% Compute total duration of stim command
dur = [];

for icmd = 1:length(stim_string)

    idxTL = strfind(stim_string{icmd},'TL');
    idxFreq = strfind(stim_string{icmd},'Freq');

    dur(icmd) = max(str2num(stim_string{icmd}(idxTL+3:idxFreq-3)))*1e-3; % [s]
end

cmdTotDuration = max(dur) + sum(cmdDelay);

% Function to convert a numerical array into a comma-separated string
    function out = cstr(in)

        out = strjoin(compose('%d',in),',');
    end

end