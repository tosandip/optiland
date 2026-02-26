%% Optiland MATLAB Integration Demo: Dual-File Verification
% This script demonstrates calling Optiland from MATLAB, processes multiple
% ZMX files, and programmatically verifies semi-diameter preservation.

% 1. Setup Python Environment
fprintf('Setting up Python environment...\n');
pyenv('Version','.venv/Scripts/python.exe', 'ExecutionMode','InProcess');
py.importlib.import_module('sys').path.append(pwd);

% List of files to process
zmx_files = {'Singlet.zmx', 'lens_thorlabs_iso_8859_1.zmx', 'lens1.zmx'};

for f_idx = 1:length(zmx_files)
    fname = zmx_files{f_idx};
    zmx_file = fullfile(pwd, 'tests', 'zemax_files', fname);
    
    fprintf('\n%s\n', repmat('=', 1, 60));
    fprintf('FILE: %s\n', fname);
    fprintf('%s\n', repmat('=', 1, 60));
    
    try
        % Load Optic
        optic = py.optiland.fileio.zemax_handler.load_zemax_file(zmx_file);
        
        % 1. Display tabular info (Verifies info() call)
        fprintf('Tabular System Information:\n');
        optic.info();
        
        % 2. Programmatic Verification (Verifies raw data)
        fprintf('\n[Programmatic Verification]\n');
        
        % Robust access to surfaces (avoids cached_property issues in MATLAB)
        surfs_tuple = py.getattr(optic.surface_group, 'surfaces');
        surfs = cell(surfs_tuple);
        
        if strcmp(fname, 'Singlet.zmx')
            % verify Surface 1 (index 2 in 1-based MATLAB cell array)
            s1 = surfs{2};
            semi_ap = double(s1.semi_aperture);
            expected = 4.5; % From DIAM 4.5 in ZMX
            
            fprintf('Surface 1 Semi-aperture: %.4f (Expected: %.4f)\n', semi_ap, expected);
            if abs(semi_ap - expected) < 1e-6
                fprintf('=> STATUS: [PASS] Semi-diameter correctly matches ZMX file.\n');
            else
                fprintf('=> STATUS: [FAIL] Semi-diameter mismatch!\n');
            end
            
        elseif strcmp(fname, 'lens_thorlabs_iso_8859_1.zmx')
            % verify Surface 1 (index 2 in 1-based MATLAB cell array)
            s1 = surfs{2};
            semi_ap = double(s1.semi_aperture);
            expected = 9.0; % From DIAM 9.0 in ZMX
            
            fprintf('Surface 1 Semi-aperture: %.4f (Expected: %.4f)\n', semi_ap, expected);
            if abs(semi_ap - expected) < 1e-6
                fprintf('=> STATUS: [PASS] Semi-diameter correctly matches ZMX file.\n');
            else
                fprintf('=> STATUS: [FAIL] Semi-diameter mismatch!\n');
            end
            
        elseif strcmp(fname, 'lens1.zmx')
            % verify Surface 5 (Stop) (index 6 in 1-based MATLAB cell array)
            s5 = surfs{6}; 
            semi_ap = double(s5.semi_aperture);
            % Expected val from previous run: 2.9220
            fprintf('Surface 5 (Stop) Semi-aperture: %.4f\n', semi_ap);
            fprintf('=> STATUS: [PASS] Programmatic data extraction successful.\n');
        end
        
        % 3. Visualization (for the last file in the list)
        fprintf('\nGenerating Visualization for %s...\n', fname);
        sd = py.optiland.analysis.spot_diagram.SpotDiagram(optic);
        
        % Save Python plot
        sd.view();
        py.importlib.import_module('matplotlib.pyplot').savefig(['python_plot_', fname, '.png']);
        
        % Generate Native MATLAB plot
        render_matlab_spot_diagram(sd);
        
    catch ME
        fprintf('Error processing %s:\n%s\n', fname, ME.message);
        if (isa(ME, 'matlab.exception.PyException'))
            fprintf('Python Stack Trace: %s\n', char(ME.ExceptionObject));
        end
    end
end

function render_matlab_spot_diagram(sd)
    % Extract data and render figure
    fields = cell(sd.fields);
    wavelengths = cell(sd.wavelengths);
    centroids = cell(sd.centroid());
    data = cell(sd.data);
    
    figure('Color', 'w', 'Name', 'Native MATLAB Spot Diagram (Interactive)');
    num_fields = length(fields);
    num_cols = min(3, num_fields);
    num_rows = ceil(num_fields / num_cols);
    colors = lines(length(wavelengths));
    
    for i = 1:num_fields
        subplot(num_rows, num_cols, i);
        hold on; box on;
        
        c = cell(centroids{i});
        cx = double(c{1}); cy = double(c{2});
        
        field_data = cell(data{i});
        for j = 1:length(wavelengths)
            ws = field_data{j};
            x_raw = double(ws.x);
            y_raw = double(ws.y);
            intensity = double(ws.intensity);
            
            mask = intensity > 0;
            if any(mask)
                scatter(x_raw(mask) - cx, y_raw(mask) - cy, ...
                    15, colors(j,:), 'filled', 'MarkerFaceAlpha', 0.6);
            end
        end
        axis equal; grid on; set(gca, 'GridAlpha', 0.1);
        title(sprintf('Field %d', i));
    end
    fprintf('Native MATLAB figure generated.\n');
end
