% 将来考虑所有配置参数放到结构体中直接传递给函数，去除重复定义
height_arr = 75:15:840;             % 高度数组
heightCount = size(height_arr, 2);  % 高度个数

% 将风速结果保存为csv
% 列名称
resultTitle={'ymd','hour','minute', 'second', 'azimuth', 'pitch', 'height', 'windspeed', 'winddirection'};
fileDir = '.\csv-data\20210802\';
resultDir = '.\result\20210802\';

csvFileTree = dir([fileDir,'*.csv']);
csvFileNum = size(csvFileTree,1);
for csvFile_Index = 1 : csvFileNum
    fprintf("loading csv file: %f%%\n", csvFile_Index/csvFileNum*100);
    struct_oriVAD = func_read_VAD_ori([fileDir, csvFileTree(csvFile_Index).name]);
    struct_calVAD = draw_sinfit(struct_oriVAD);
    
    % 存excel
    fprintf("saving data...\n");
    perExcelRow = 0; %单个excel行数
    for struct_oriVAD_index = 1 : size(struct_oriVAD, 2)
        perExcelRow = perExcelRow + sum(~isnan(struct_oriVAD(struct_oriVAD_index).azimuth), 2);
    end
    perExcelRow = perExcelRow * heightCount; % 距离
    singleExcelData = NaN(perExcelRow, 9);
    
    currentExcelRow = 1;
    for struct_oriVAD_index = 1 : size(struct_oriVAD, 2) %结构体数组遍历
        currentAzimuthCount = sum(~isnan(struct_oriVAD(struct_oriVAD_index).azimuth), 2); % 当前结构体内有效Az数
        inStructRowCount = currentAzimuthCount*heightCount; % 该结构体内转换二维表后行数
        singleExcelData(currentExcelRow:inStructRowCount + (currentExcelRow-1), ...,
                        1) = struct_oriVAD(struct_oriVAD_index).time_ymd; % ymd
        singleExcelData(currentExcelRow:inStructRowCount + (currentExcelRow-1), ...,
                        2) = struct_oriVAD(struct_oriVAD_index).time_hour; % h
        singleExcelData(currentExcelRow:inStructRowCount + (currentExcelRow-1), ...,
                        3) = struct_oriVAD(struct_oriVAD_index).time_minute; % m
        singleExcelData(currentExcelRow:inStructRowCount + (currentExcelRow-1), ...,
                        4) = struct_oriVAD(struct_oriVAD_index).time_second; % s
        for azimut_index = 1 : currentAzimuthCount %便利结构体内az (39) 每个az拓展成9个高度
            inAzimutOffset = (azimut_index-1)*heightCount; % 0, heightCount (9), 18, ...
            singleExcelData(currentExcelRow+inAzimutOffset:currentExcelRow+inAzimutOffset+(heightCount-1), ...,
                            5) = struct_oriVAD(struct_oriVAD_index).azimuth(azimut_index);
            singleExcelData(currentExcelRow+inAzimutOffset:currentExcelRow+inAzimutOffset+(heightCount-1), ...,
                            6) = struct_oriVAD(struct_oriVAD_index).pitch(azimut_index);
            singleExcelData(currentExcelRow+inAzimutOffset:currentExcelRow+inAzimutOffset+(heightCount-1), ...,
                            7) = height_arr';
            singleExcelData(currentExcelRow+inAzimutOffset:currentExcelRow+inAzimutOffset+(heightCount-1), ...,
                            8) = struct_calVAD(struct_oriVAD_index).windspeed(:, 1);
            singleExcelData(currentExcelRow+inAzimutOffset:currentExcelRow+inAzimutOffset+(heightCount-1), ...,
                            9) = struct_calVAD(struct_oriVAD_index).windspeed(:, 2);
        end
        currentExcelRow = currentExcelRow + inStructRowCount;
    end

    %生成表格，按列生成
    % VariableNames 参数用于设置列头
    result_table = array2table(singleExcelData, 'VariableNames', resultTitle);
    writetable(result_table, [resultDir, csvFileTree(csvFile_Index).name]);
    fprintf("save sucessful, csv_index = %d\n", csvFile_Index);
end

