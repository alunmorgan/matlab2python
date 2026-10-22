function start_python_port(input_location, temp_file_location)
% Does the initial rearrangement for a python port of matlab code.
% A folder of matlab functions is converted into a file of python functions.

[code_folders, code_path] = dir_list_gen_tree(input_location, 'dirs', 1);
for qe = 1:length(code_folders)
    if strcmp(code_folders{qe}(1), '.') || contains(code_path{qe}, '.git')
        flag(qe) = 0;
    else
        flag(qe) = 1;
    end %if
end %for
code_folders = code_folders(flag==1);
code_path = code_path(flag==1);
input_pattern = input_location;
if ispc == 1
    input_pattern = regexprep(input_pattern, '\\', '\\\\');
    input_pattern = strcat(input_pattern, '\\');
end %if
for hs = 1:length(code_path)
    code_path{hs} = regexprep(code_path{hs}, input_pattern, '');
%     input_pattern = strcat(input_pattern, '\/');
end %for
if isempty(code_folders)
    disp('No code found')
    return
end %if

if exist(fullfile(input_location, 'python_port'), "dir")
    error("Output folder already exists")
else
    mkdir(fullfile(input_location, 'python_port'))
end %if

for kd = 1:length(code_folders)
    code_list = {};
    sub_folder = fullfile(input_location, code_path{kd}, code_folders{kd});
    [code_files, ~] = dir_list_gen(sub_folder, 'm', 'quiet_flag', 1);
    if isempty(code_files)
        continue
    end
    if ~exist(fullfile(input_location, 'python_port', code_path{kd}), 'dir')
        mkdir(fullfile(input_location, 'python_port', code_path{kd}))
    end %if
    fprintf('\n*')
    for ks = 1:length(code_files)
        fprintf('.')
        file_loc = fullfile(sub_folder, code_files{ks});
        temp_loc = fullfile(temp_file_location, code_files{ks});
        t = matlab.desktop.editor.openDocument(file_loc);
        t.smartIndentContents;
        t.saveAs(temp_loc)
        t.close
        fileID = fopen(temp_loc);
        while 1==1
            temp = fgetl(fileID);
            if temp == -1
                break
            else
                code_list = cat(1, code_list, temp);
            end %if
        end %while
        fclose(fileID);
        delete(temp_loc)
    end %for

    outputs = '';
    outputs_previous = '';
    hs = 1;
    for jg = 1:length(code_list)
        if contains(code_list{hs}, 'function ')
            outputs = regexp(code_list{hs}, '^\s*function\s+\[*([^[]]*)\]*\s*=\s*(.*)', 'tokens');
            if ~isempty(outputs)
                func = outputs{1}{2};
                outputs = outputs{1}{1};
                code_list(hs+2:end+2) = code_list(hs:end);
                code_list{hs} = ['    return ', outputs_previous];
                code_list{hs + 1} = '';
                outputs_previous = outputs;
                outputs = '';
                hs = hs +2;
                code_list{hs} = ['function ', func];
            end %if
        else
            code_list{hs} = ['    ', code_list{hs}];
        end %if
        code_list{hs} = regexprep(code_list{hs},'%', '#');
        code_list{hs} = regexprep(code_list{hs},';\s*$', '');
        code_list{hs} = regexprep(code_list{hs},'\.\.\.\s*$', '');
        code_list{hs} = regexprep(code_list{hs},'function\s*(.*)', 'def $1:');
        code_list{hs} = regexprep(code_list{hs},'(^\s*for)(.*)=(.*):(.*)', '$1$2 in range($3, $4):');
        code_list{hs} = regexprep(code_list{hs},'(^\s*)elseif(.*)', '$1elif$2:');
        code_list{hs} = regexprep(code_list{hs},'(^\s*if)(.*)', '$1$2:');
        code_list{hs} = regexprep(code_list{hs},'(^\s*else)(.*)', '$1$2:');
        code_list{hs} = regexprep(code_list{hs},'(^\s*while)(.*)', '$1$2:');
        code_list{hs} = regexprep(code_list{hs},'(^\s*end)\s+.*', '');
        code_list{hs} = regexprep(code_list{hs},'(^\s*end)$', '');
        code_list{hs} = regexprep(code_list{hs},'(\s*)disp(.*)', '$1print$2');
        code_list{hs} = regexprep(code_list{hs},'(\s*)fprintf(.*)', '$1print$2');
        code_list{hs} = regexprep(code_list{hs},'(\s*)sprintf(.*)', '$1print$2');
        code_list{hs} = regexprep(code_list{hs},'(\s*)length\((.*)', '$1len\($2');
        code_list{hs} = regexprep(code_list{hs},'(\s*)num2str(.*)', '$1$2');
        code_list{hs} = regexprep(code_list{hs},'{(\w*)\s*,\s*(\w*)}', '[$1][$2]');
        code_list{hs} = regexprep(code_list{hs},'{(\w*)}', '[$1]');
        for hgr = 1:10
            code_list{hs} = regexprep(code_list{hs},'(\s*)\.\(([\w''\[\]]*)\)(.*)', '$1[$2]$3');
        end %for
        for ha = 1:10
            code_list{hs} = regexprep(code_list{hs},'(\s*)\.(\w*)(.*)', '$1[''$2'']$3');
        end %for
        code_list{hs} = regexprep(code_list{hs},'(\s*)isfield\((.*)\s*,\s*(.*)\)', '$1$3 in $2');
        code_list{hs} = regexprep(code_list{hs},'(\s*)~isempty\(([^\)]*)\)', '$1 $2');
        code_list{hs} = regexprep(code_list{hs},'(\s*)~isempty\(([^\)]*)\)', '$1 $2');
        code_list{hs} = regexprep(code_list{hs},'(\s*)~isempty\(([^\)]*)\)', '$1 $2');
        code_list{hs} = regexprep(code_list{hs},'(\s*)isempty\(([^\)]*)\)', '$1not $2');
        code_list{hs} = regexprep(code_list{hs},'(\s*)isempty\(([^\)]*)\)', '$1not $2');
        code_list{hs} = regexprep(code_list{hs},'(\s*)isempty\(([^\)]*)\)', '$1not $2');
        code_list{hs} = regexprep(code_list{hs},'(^\s*try)(.*)', '$1$2:');
        code_list{hs} = regexprep(code_list{hs},'(^\s*)catch(.*)', '$1except$2:');
        code_list{hs} = regexprep(code_list{hs},'||', 'or');
        code_list{hs} = regexprep(code_list{hs},'&&', 'and');
        code_list{hs} = regexprep(code_list{hs},'~=', '!=');
        for hs = 1:5
            code_list{hs} = regexprep(code_list{hs},'(\s*\[[^\[\]]*)~([^\[\]]*\]\s*=)', ['$1 _',hs,' $2']);
        end %for
        for ks = 1:10
            code_list{hs} = regexprep(code_list{hs},'(=\s*\[[^\[\]]+)\s+([^,][^\[\]]+\])', '$1, $2');
        end %for


        hs = hs +1;
    end %for
    writelines(code_list,fullfile(input_location, 'python_port', code_path{kd}, [code_folders{kd}, '.py']))
end %for
