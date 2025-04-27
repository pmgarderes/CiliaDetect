function view_nd2_with_cilia_gui(stack, params, uniqueDetections)
% stack: cell array of {Y x X x Z} images per channel
% params: struct with detection parameters:
%   .windowSize, .minArea, .maxArea, .minElongation

adaptiveSensitivity = params.adaptiveSensitivity;
FirstTime = 1; 
numChannels = numel(stack);
currentChannel = 1;
numSlices = size(stack{1}, 3);
currentZ = 1;

% Store detections
ciliaDetections = {};
roiHandles = {};  % One per detection

% Create fullscreen figure
fig = figure('Name', 'ND2 Viewer + Cilia Detection (Spacebar)', ...
    'KeyPressFcn', @keyHandler, ...
    'Color', 'k', ...
    'Units', 'normalized', ...
    'OuterPosition', [0 0 1 1]);

ax = axes('Parent', fig);
% if ciliaDetections is already defined
ciliaDetections = uniqueDetections;



imgHandle = imagesc(stack{currentChannel}(:,:,currentZ), 'Parent', ax);
colormap('gray');
axis image off;

title(ax, sprintf('Channel %d | Z-plane %d/%d', ...
    currentChannel, currentZ, numSlices), ...
    'Color', 'w', 'FontSize', 18);



% Helper function to update display
    function updateDisplay()
        imgHandle.CData = stack{currentChannel}(:,:,currentZ);
        title(ax, sprintf('Channel %d | Z-plane %d/%d', ...
            currentChannel, currentZ, numSlices), ...
            'Color', 'w', 'FontSize', 18);
    end

% Key handler
    function keyHandler(~, event)
        switch event.Key
            case 'add'  % '+' key on main keyboard
                adaptiveSensitivity = min(adaptiveSensitivity + 0.05, 1.0);
                fprintf('Increased sensitivity: %.2f\n', adaptiveSensitivity);
            case 'subtract'  % '-' key on main keyboard
                adaptiveSensitivity = max(adaptiveSensitivity - 0.05, 0.05);
                fprintf('Decreased sensitivity: %.2f\n', adaptiveSensitivity);
            case 'rightarrow'
                currentChannel = mod(currentChannel, numChannels) + 1;
                updateDisplay();
            case 'leftarrow'
                currentChannel = mod(currentChannel - 2, numChannels) + 1;
                updateDisplay();
            case 'uparrow'
                currentZ = min(currentZ + 1, numSlices);
                updateDisplay();
            case 'downarrow'
                currentZ = max(currentZ - 1, 1);
                updateDisplay();
            case 'u'  % Undo last detection
                if ~isempty(ciliaDetections)
                    % Remove detection
                    ciliaDetections(end) = [];
                    
                    % Delete graphical objects
                    lastHandles = roiHandles{end};
                    for h = lastHandles
                        if isvalid(h)
                            delete(h);
                        end
                    end
                    roiHandles(end) = [];
                    
                    disp('Last detection undone.');
                else
                    disp('No detections to undo.');
                end
            case 'space'
                % Get mouse location in image coordinates
                cp = get(ax, 'CurrentPoint');
                x = round(cp(1,1));
                y = round(cp(1,2));
                
                % Validate position
                sz = size(stack{currentChannel});
                if x < 1 || x > sz(2) || y < 1 || y > sz(1)
                    disp('Click was out of bounds. Ignoring.');
                    return;
                end
                
                % Get current image
                currentFrame = stack{currentChannel}(:,:,currentZ);
                
                % Run cilia detection
                mask = detect_cilium_from_seed2(currentFrame, [x, y], params,adaptiveSensitivity);
                disp([ 'area ' num2str(sum(mask(:)))]) ; %  ciliaDetections{1}.mask(:)))])
                
                % Save result
                detectionStruct = struct( ...
                    'channel', currentChannel, ...
                    'zplane', currentZ, ...
                    'click', [x, y], ...
                    'mask', mask);
                ciliaDetections{end+1} = detectionStruct;
                
                
                % Overlay boundary of the new mask
                hold(ax, 'on');
                
                % relaod data 
                if FirstTime & ~isempty(uniqueDetections)
                    % Define a colormap for different detections
                    colors = lines(numel(uniqueDetections));
                    for i = 1:numel(uniqueDetections)
                        det = uniqueDetections{i};
                        mask = det.mask;
                        zplane = det.zplane;
                        channel = det.channel;

                        % Check if the detection corresponds to the current channel and z-plane
                        if channel == currentChannel % && zplane == currentZ
                            % Find the contour of the mask
                            B = bwboundaries(mask);
                            for k = 1:length(B)
                                boundary = B{k};
                                % Plot the boundary
                                plot(ax, boundary(:,2), boundary(:,1), 'Color', colors(i,:), 'LineWidth', 1.5);
                            end
                        end
                    end
                    FirstTime = 0 ; 
                end
                
                % Find boundary points
                boundaries = bwboundaries(mask);
                roiGroup = gobjects(0); % Collect handles for this detection
                for k = 1:length(boundaries)
                    B = boundaries{k};
                    h = plot(ax, B(:,2), B(:,1), 'g-', 'LineWidth', 1.5);
                    roiGroup(end+1) = h;
                end
                hPoint = plot(ax, x, y, 'g+', 'MarkerSize', 10, 'LineWidth', 1.5);
                roiGroup(end+1) = hPoint;
                % Store handles and detection

                roiHandles{end+1} = roiGroup;
            case {'escape', 'q'}
                close(fig);
        end
    end

% On close: save detections to base workspace
set(fig, 'CloseRequestFcn', @closeHandler);
    function closeHandler(~, ~)
        assignin('base', 'ciliaDetections', ciliaDetections);
        delete(fig);
        disp('Cilia detections saved to variable: ciliaDetections');
    end
end




