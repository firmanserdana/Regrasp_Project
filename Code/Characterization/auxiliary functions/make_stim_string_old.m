function [stim_string,safe] = make_stim_string(mode,stim_params,elec,safeLimit)

safe = 1;               % by default stim is SAFE = below safety limits

% Components of stim string
elec_string = 'Elect='; % electrode
TL_string = 'TL=';      % train length [ms]
freq_string = 'Freq=';  % frequency [Hz]
PW_string = 'Dur=';     % pulse-width [ms]
amp_string = 'Amp=';    % amplitude [steps]
TD_string = 'TD=';      % train delay [ms]
FS_string = 'FS=';      % fast settle [ms]
PL_string = 'PL=';      % polarity (1 = cathodic-first, 0 = anodic-first)

% Stim parameters that do not change
FS = 0;                 % no fast settle
PL = 1;                 % cathodic-first pulses
amp_step_size = 5;      % [uA]   TO CHECK THIIIIIIIIS

% Set stim parameters
switch mode

    case 1          % ----- Single pulse -----
        amp = stim_params.('single_pulse_ampl');    % [µA]
        amp_steps = floor(amp / amp_step_size);     % [steps]
        PW = stim_params.('single_pulse_PW')*1e-3;  % [ms]
        freq = 1;                                   % [Hz]
        TL = 500;                                   % [ms]
        TD = 0;                                     % [ms]

        elec_string = [elec_string num2str(elec) ','];
        TL_string = [TL_string num2str(TL) ','];
        freq_string = [freq_string num2str(freq) ','];
        PW_string = [PW_string num2str(PW) ','];
        amp_string = [amp_string num2str(amp_steps) ','];
        TD_string = [TD_string num2str(TD) ','];
        FS_string = [FS_string num2str(FS) ','];
        PL_string = [PL_string num2str(PL) ','];

        if amp*PW*1e3 > safeLimit
            safe = 0;
        end


    case 2          % ----- Single burst -----
        amp = stim_params.('single_burst_ampl');     % [µA]
        amp_steps = floor(amp / amp_step_size);      % [steps]
        PW = stim_params.('single_burst_PW')*1e-3;   % [ms]
        freq = stim_params.('single_burst_freq');    % [Hz]
        TL = stim_params.('single_burst_dur')*1e3;   % [ms]
        TD = 0;                                      % [ms]

        elec_string = [elec_string num2str(elec) ','];
        TL_string = [TL_string num2str(TL) ','];
        freq_string = [freq_string num2str(freq) ','];
        PW_string = [PW_string num2str(PW) ','];
        amp_string = [amp_string num2str(amp_steps) ','];
        TD_string = [TD_string num2str(TD) ','];
        FS_string = [FS_string num2str(FS) ','];
        PL_string = [PL_string num2str(PL) ','];

        if amp*PW*1e3 > safeLimit
            safe = 0;
        end

    case 3          % ----- Recruitment curves -----
        amp_min = stim_params.('RC_min_ampl');      % [uA]
        amp_max = stim_params.('RC_max_ampl');      % [uA]
        amp_incr = stim_params.('RC_amp_step');     % [uA]
        n_incr = floor((amp_max-amp_min)/amp_incr);
        reps = stim_params.('RC_reps');
        PW = stim_params.('RC_PW')*1e-3;            % [ms]
        freq = stim_params.('RC_freq');             % [Hz]
        TL = (reps-0.5)/freq*1e3;                   % [ms]

        for iA = 1:n_incr
            amp = amp_min + (iA-1)*amp_incr;        % [uA]
            amp_steps = floor(amp / amp_step_size); % [steps]
            TD = (iA-1) * reps/freq*1e3;            % [ms]

            elec_string = [elec_string num2str(elec) ','];
            TL_string = [TL_string num2str(TL) ','];
            freq_string = [freq_string num2str(freq) ','];
            PW_string = [PW_string num2str(PW) ','];
            amp_string = [amp_string num2str(amp_steps) ','];
            TD_string = [TD_string num2str(TD) ','];
            FS_string = [FS_string num2str(FS) ','];
            PL_string = [PL_string num2str(PL) ','];

            if amp*PW*1e3 > safeLimit
                safe = 0;
                break;
            end
        end

    case 4          % ----- AM Bursts -----
        freq = stim_params.('AM_burst_intra_burst_freq');   % [Hz]
        PW = stim_params.('AM_burst_PW')*1e-3;              % [ms]
        TL = stim_params.('AM_burst_dur');                  % [ms]
        IBI = stim_params.('AM_burst_inter_burst_int');     % [ms]
        amp_min = stim_params.('AM_burst_min_ampl');        % [uA]
        amp_max = stim_params.('AM_burst_max_ampl');        % [uA]
        amp_incr = stim_params.('AM_burst_amp_step');       % [uA]
        n_incr = floor((amp_max-amp_min)/amp_incr);
        reps = stim_params.('AM_burst_reps');

        for iA = 1:n_incr
            amp = amp_min + (iA-1)*amp_incr;                % [uA]
            amp_steps = floor(amp / amp_step_size);         % [steps]
            TD = (iA-1) * (TL+IBI);                         % [ms]

            elec_string = [elec_string num2str(elec) ','];
            TL_string = [TL_string num2str(TL) ','];
            freq_string = [freq_string num2str(freq) ','];
            PW_string = [PW_string num2str(PW) ','];
            amp_string = [amp_string num2str(amp_steps) ','];
            TD_string = [TD_string num2str(TD) ','];
            FS_string = [FS_string num2str(FS) ','];
            PL_string = [PL_string num2str(PL) ','];

            if amp*PW*1e3 > safeLimit
                safe = 0;
                break;
            end
        end

    case 5          % ----- FM Bursts -----
        amp = stim_params.('FM_burst_ampl');                % [uA]
        amp_steps = floor(amp / amp_step_size);             % [steps]
        PW = stim_params.('FM_burst_PW')*1e-3;              % [ms]
        TL = stim_params.('FM_burst_dur');                  % [ms]
        IBI = stim_params.('FM_burst_inter_burst_int');     % [ms]
        freq_min = stim_params.('FM_burst_min_freq');       % [Hz]
        freq_max = stim_params.('FM_burst_max_freq');       % [Hz]
        freq_incr = stim_params.('FM_burst_freq_step');     % [Hz]
        n_incr = floor((freq_max-freq_min)/freq_incr);
        reps = stim_params.('FM_burst_reps');

        for iF = 1:n_incr
            freq = freq_min + (iF-1)*freq_incr;             % [uA]
            TD = (iF-1) * (TL+IBI);                         % [ms]

            elec_string = [elec_string num2str(elec) ','];
            TL_string = [TL_string num2str(TL) ','];
            freq_string = [freq_string num2str(freq) ','];
            PW_string = [PW_string num2str(PW) ','];
            amp_string = [amp_string num2str(amp_steps) ','];
            TD_string = [TD_string num2str(TD) ','];
            FS_string = [FS_string num2str(FS) ','];
            PL_string = [PL_string num2str(PL) ','];
        end

        if amp*PW*1e3 > safeLimit
            safe = 0;
        end

    case 6          % ----- Tonic -----
        amp = stim_params.('tonic_ampl');           % [uA]
        amp_steps = floor(amp / amp_step_size);     % [steps]
        PW = stim_params.('tonic_PW')*1e-3;         % [ms]
        freq = stim_params.('tonic_freq');          % [Hz]
        TL = stim_params.('tonic_train_dur')*1e3;       % [ms]
        TD = 0;                                     % [ms]

        elec_string = [elec_string num2str(elec) ','];
        TL_string = [TL_string num2str(TL) ','];
        freq_string = [freq_string num2str(freq) ','];
        PW_string = [PW_string num2str(PW) ','];
        amp_string = [amp_string num2str(amp_steps) ','];
        TD_string = [TD_string num2str(TD) ','];
        FS_string = [FS_string num2str(FS) ','];
        PL_string = [PL_string num2str(PL) ','];

        if amp*PW*1e3 > safeLimit
            safe = 0;
        end
end

% Complete the stim string
stim_string = [elec_string ';' TL_string ';' freq_string ';' PW_string ';' ...
    amp_string ';' TD_string ';' FS_string ';' PL_string ';'];

end