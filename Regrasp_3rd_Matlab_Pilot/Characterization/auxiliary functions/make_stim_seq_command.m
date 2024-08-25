function cmd = make_stim_seq_command(mode,stim_params,elec)

NIP_clock_us = 1e6/3e4; % 33.333 us
amp_step_size = 5; % [uA]   TO CHECK THIIIIIIIIS

switch mode

    case 1          % ----- Single pulse -----
        amp = stim_params.('single_pulse_ampl');    % [µA]
        amp_steps = floor(amp / amp_step_size);     % [steps]
        PW = stim_params.('single_pulse_PW');       % [µs]
        PW_cycles = floor(PW / NIP_clock_us);       % [clock cycles]
        % Define stim seq command
        % create the overall header values defining electrode, frequency,
        % and number of repeats.  This will give a pulse on electrode
        % 'elec'. 'period' = 5 times the PW of the pulse to give enough
        % time for the pulse
        cmd = struct('elec', elec, 'period', (PW*2)/NIP_clock_us+2, 'repeats', 1, 'action', 'immed');
        % Create the first phase (cathodic) for stimulation.  This has a
        % duration of PW µs (ie, 6 clock cycles at 30 kHz = 200µs), amplitude
        % given by the number of steps by the current amplitude step size
        % (set on trellis.app) and negative polarity
        cmd.seq(1) = struct('length', PW_cycles, 'ampl', amp_steps, 'pol', 0, ...
            'fs', 0, 'enable', 1, 'delay', 0, 'ampSelect', 1);
        % Create the inter-phase interval. The amplitude is zero.  The
        % stimulation amp is still used so that the stim markers sent by
        % the NIP will properly contain this phase.
        cmd.seq(2) = struct('length', 1, 'ampl', 0, 'pol', 0, ...
            'fs', 0, 'enable', 0, 'delay', 0, 'ampSelect', 1);
        % Create the second, anodic phase.  This has a duration of PW µs,
        % same amplitude opposite sign (positive polarity).
        cmd.seq(3) = struct('length', PW_cycles, 'ampl', amp_steps, 'pol', 1, ...
            'fs', 0, 'enable', 1, 'delay', 0, 'ampSelect', 1);

    case 2          % ----- Single burst -----
        amp = stim_params.('single_burst_ampl');     % [µA]
        amp_steps = floor(amp / amp_step_size);      % [steps]
        PW = stim_params.('single_burst_PW');        % [µs]
        PW_cycles = floor(PW / NIP_clock_us);        % [clock cycles]
        freq = stim_params.('single_burst_freq');    % [Hz]
        TL = stim_params.('single_burst_dur');       % [s]
        

        cmd = struct('elec', elec, 'period', round(1/freq*1e6/NIP_clock_us), 'repeats', TL*freq);
        cmd.seq(1) = struct('length', PW_cycles, 'ampl', amp_steps, 'pol', 0, ...
            'fs', 0, 'enable', 1, 'delay', 0, 'ampSelect', 1);
        cmd.seq(2) = struct('length', 1, 'ampl', 0, 'pol', 0, ...
            'fs', 0, 'enable', 0, 'delay', 0, 'ampSelect', 1);
        cmd.seq(3) = struct('length', PW_cycles, 'ampl', amp_steps, 'pol', 1, ...
            'fs', 0, 'enable', 1, 'delay', 0, 'ampSelect', 1);
        
    case 3          % ----- Recruitment curves -----
        amp_min = stim_params.('RC_min_ampl');
        amp_max = stim_params.('RC_max_ampl');
        amp_step = stim_params.('RC_amp_step');
        n_steps = floor((amp_max-amp_min)/amp_step);
        reps = stim_params.('RC_reps');
        PW = stim_params.('RC_PW');
        stim_params.('RC_freq');

        cmd = struct([]);

        for iA = 1:n_steps
            cmd(iA).elec = elec;
            cmd(iA).period = [];
            cmd(iA).repeats = reps;
            cmd(iA).action = 'immed';

            cmd(iA).seq(1) = 

        end

    case 4
        stim_params.('AM_burst_intra_burst_int');
        stim_params.('AM_burst_inter_burst_int');
        stim_params.('AM_burst_dur');
        stim_params.('AM_burst_min_ampl');
        stim_params.('AM_burst_max_ampl');
        stim_params.('AM_burst_amp_step');
        stim_params.('AM_burst_reps');
        stim_params.('AM_burst_PW');
    case 5
        stim_params.('FM_burst_ampl');
        stim_params.('FM_burst_inter_burst_int');
        stim_params.('FM_burst_dur');
        stim_params.('FM_burst_min_freq');
        stim_params.('FM_burst_max_freq');
        stim_params.('FM_burst_freq_step');
        stim_params.('FM_burst_reps');
        stim_params.('FM_burst_PW');
    case 6
        stim_params.('tonic_ampl');
        stim_params.('tonic_PW');
        stim_params.('tonic_freq');
        stim_params.('tonic_train_dur');
end
end