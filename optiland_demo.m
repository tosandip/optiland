%% Optiland MATLAB Integration Demo: Dual Plotting Comparison
% This script demonstrates how to call Optiland from MATLAB and compares
% Python-based plotting (via Matplotlib) with native MATLAB plotting.

% 1. Setup MPyReq and Python Environment
fprintf('Setting up Python environment using MPyReq...\n');

% Set installation folder for Python environment
mpy_folder = fullfile(pwd, '.mpyreq');
if ~exist(mpy_folder, 'dir')
    mkdir(mpy_folder);
end

% 2. Add Optiland to Python Path
fprintf('Adding Optiland to Python path...\n');
py.importlib.import_module('sys').path.append(pwd);

% 3. Import ZMX File
zmx_file = fullfile(pwd, 'tests', 'zemax_files', 'lens1.zmx');
fprintf('Loading ZMX file: %s\n', zmx_file);

try
    % Call optiland.fileio.zemax_handler.load_zemax_file
    optic = py.optiland.fileio.zemax_handler.load_zemax_file(zmx_file);
    fprintf('Successfully created Optiland Optic object.\n');
    
    % 4. Initialize Spot Diagram Analysis in Python
    fprintf('Initializing Spot Diagram analysis...\n');
    sd = py.optiland.analysis.spot_diagram.SpotDiagram(optic);
    
    % --- Part A: Python Plotting (Matplotlib) ---
    fprintf('Generating Spot Diagram via Python (Matplotlib)...\n');
    sd.view();
    
    % Save the Python plot to comparison
    plt = py.importlib.import_module('matplotlib.pyplot');
    plt.savefig('python_spot_diagram.png');
    fprintf('Python plot saved to python_spot_diagram.png\n');
    
    % --- Part B: Native MATLAB Plotting ---
    fprintf('Generating Spot Diagram via Native MATLAB plotting...\n');
    
    % Extract metadata from Python object
    fields = cell(sd.fields);
    wavelengths = cell(sd.wavelengths);
    centroids = cell(sd.centroid());
    data = cell(sd.data);
    
    num_fields = length(fields);
    num_wavelengths = length(wavelengths);
    
    % Setup figure
    figure('Name', 'Native MATLAB Spot Diagram', 'Color', 'w', 'Position', [100, 100, 1000, 400]);
    num_cols = min(3, num_fields);
    num_rows = ceil(num_fields / num_cols);
    
    colors = lines(num_wavelengths);
    markers = {'o', 's', '^', 'd', 'v', 'p', 'h'};
    
    for i = 1:num_fields
        subplot(num_rows, num_cols, i);
        hold on;
        box on;
        
        % Get centroid for centering (consistent with Python logic)
        c = cell(centroids{i});
        cx = double(c{1});
        cy = double(c{2});
        
        field_data = cell(data{i});
        for j = 1:num_wavelengths
            wave_spot_data = field_data{j};
            
            % Convert Python arrays to MATLAB doubles
            x_raw = double(wave_spot_data.x);
            y_raw = double(wave_spot_data.y);
            intensity = double(wave_spot_data.intensity);
            
            % Center the data
            x = x_raw - cx;
            y = y_raw - cy;
            
            % Filter out rays with zero intensity
            mask = intensity > 0;
            if any(mask)
                marker = markers{mod(j-1, length(markers)) + 1};
                scatter(x(mask), y(mask), 15, colors(j, :), marker, 'filled', ...
                    'DisplayName', sprintf('%.4f um', double(wavelengths{j})), ...
                    'MarkerFaceAlpha', 0.6);
            end
        end
        
        % Finalize subplot
        axis equal;
        grid on;
        set(gca, 'GridAlpha', 0.15);
        xlabel('X (mm)');
        ylabel('Y (mm)');
        
        f_coords = cell(fields{i});
        title(sprintf('Hx: %.3f, Hy: %.3f', double(f_coords{1}), double(f_coords{2})));
    end
    
    % Add a shared legend
    hL = legend('show');
    set(hL, 'Location', 'southoutside', 'Orientation', 'horizontal');
    
    fprintf('Native MATLAB spot diagram generated successfully.\n');
    fprintf('You can now compare "python_spot_diagram.png" with the active MATLAB figure.\n');
    
catch ME
    fprintf('Error during execution: %s\n', ME.message);
    if (isa(ME, 'matlab.exception.PyException'))
        fprintf('Python Error details: %s\n', char(ME.ExceptionObject));
    end
end
