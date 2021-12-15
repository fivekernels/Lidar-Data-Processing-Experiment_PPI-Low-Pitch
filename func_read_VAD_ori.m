function struct_oriVAD = func_read_VAD_ori(filename)

% clear variables;

if ( nargin < 1 )
    filename = '.\csv-data\20210820\level0\CDL_3D10K_lidar_PPI_FromAzimuth0.00_ToAzimuth180.00_PitchAngle3.00_Resolution015_StartIndex005_LOSWind_20210820 000039.csv';
end

% 源数据列含义
% const_header_oritext_datetime  = 1;
% const_header_oritext_direction = 5;
% const_header_oridata_azimuth           = 1;
% const_header_oridata_pitch             = 2;
const_header_oridata_offsetdata        = 6;
const_header_oridata_windspeed         = 1;
const_header_oridata_SNR               = 2;
const_header_oridata_SpectralWidth     = 3;
const_header_oridata_SpectralIntensity = 4;
per_oridata_height = 4; % 每个高度的列数
height_arr = 75:15:840; % 高度数组
height_count = size(height_arr, 2);
% 读数据 结构体
field_time_ymd = 'time_ymd';
field_time_hour = 'time_hour';
field_time_minute = 'time_minute';
field_time_second = 'time_second';
field_pitch = 'pitch'; % 仰角 [0-360]
field_azimuth = 'azimuth'; % 朝向
field_windspeed = 'windspeed'; % 高度 \ [0-360]
field_windSNR = 'windSNR'; % 高度 \ [0-360]
% 读数据
% per_group_dir = (0:12:360);
groupCount = 65; % 可以适当分配的稍大一点，剩余的为NaN，将来考虑将剩余的删除或不要以该配置作为强制分组依据
% per_group_dir(groupCount) = 0;

ori_csv_data = import_VAD_csv(filename);
rows_ori_csv = size(ori_csv_data.Date_time, 1);

% 结构体预分配
ori_struct = struct( field_time_ymd, NaN, ...,
                     field_time_hour, NaN, ...,
                     field_time_minute, NaN, ...,
                     field_time_second, NaN, ...,
                     field_pitch, NaN(1, groupCount), ...,
                     field_azimuth, NaN(1, groupCount), ...,
                     field_windspeed, NaN(height_count, groupCount), ...,
                     field_windSNR, NaN(height_count, groupCount) ...,
                   );
ori_struct = repmat( ori_struct, [1 ceil(rows_ori_csv/groupCount)] );

% 组合数据
csvdataRow_Index = 1; % 原始数据行计数
j = 1; % 结构体计数
while csvdataRow_Index <= rows_ori_csv % 行数
    fprintf("loading csv: %f%%\n", csvdataRow_Index/rows_ori_csv*100);
    singleStructWindSpeed = NaN(height_count, groupCount);
    singleStructSNR = NaN(height_count, groupCount);
    singleStructPitch = NaN(1, groupCount);
    singleStructAzimuth = NaN(1, groupCount);
    lastAzimuth = 0; % 上一个朝向角
    for dirIndex = 1:groupCount % 同组内不同朝向
        if ( csvdataRow_Index+dirIndex-1 > rows_ori_csv ) || ..., % 当前越界
           ( ori_csv_data.Azimuth(csvdataRow_Index+dirIndex-1) < lastAzimuth ) % 单组数据不完整            
            % 取当前平均时间
%             datetimeStr = ori_csv_data.Date_time{csvdataRow_Index};
            datetimeStr = ori_csv_data.Date_time{ csvdataRow_Index + floor((dirIndex-1)/2) };
            % 寻找下一组
            csvdataRow_Index = csvdataRow_Index + dirIndex - 1;
%             while true
%                 if ( csvdataRow_Index+1 > rows_ori_csv ) || ..., % 最后一行
%                    ( ori_csv_data.Azimuth(csvdataRow_Index+1) <= lastAzimuth )
%                     break;
%                 end
%                 csvdataRow_Index = csvdataRow_Index + 1;
%             end
            break; % for 组内
        else
            % 取单行i+dirIndex-1风速和信噪比
            for heightIndex = 1:height_count %读源数据第i行 j遍历所有距离
                singleStructWindSpeed(heightIndex, dirIndex) = ori_csv_data{csvdataRow_Index+dirIndex-1, ...,
                    (heightIndex-1)*per_oridata_height+const_header_oridata_windspeed+const_header_oridata_offsetdata};
                singleStructSNR(heightIndex, dirIndex) = ori_csv_data{csvdataRow_Index+dirIndex-1, ...,
                    (heightIndex-1)*per_oridata_height+const_header_oridata_SNR+const_header_oridata_offsetdata};
            end
            singleStructPitch(dirIndex) = ori_csv_data.Pitch(csvdataRow_Index+dirIndex-1);
            singleStructAzimuth(dirIndex) = ori_csv_data.Azimuth(csvdataRow_Index+dirIndex-1);
%             disp(singleStructAzimuth(dirIndex));
            lastAzimuth = ori_csv_data.Azimuth(csvdataRow_Index+dirIndex-1);
            if dirIndex == groupCount
                % 同组平均时间
                datetimeStr = ori_csv_data.Date_time{ csvdataRow_Index + floor((groupCount-1)/2) };
                csvdataRow_Index = csvdataRow_Index + groupCount;
            end
        end % if 判断数据完整
    end % for 一组循环

    % 分割时间字符串
    splitSpace = strsplit(datetimeStr,' ');
    ymd = str2double(splitSpace(1));
    hms = strsplit(splitSpace{2},':');
    hour = str2double(hms{1});
    minute = str2double(hms{2});
    second = str2double(hms{3});
    
    ori_struct(j) = struct( field_time_ymd, ymd, ...,
                     field_time_hour, hour, ...,
                     field_time_minute, minute, ...,
                     field_time_second, second, ...,
                     field_pitch, singleStructPitch, ...,
                     field_azimuth, singleStructAzimuth, ...,
                     field_windspeed, singleStructWindSpeed, ...,
                     field_windSNR, singleStructSNR ...,
                   );
    
    j = j + 1;
end
struct_oriVAD = ori_struct;
end

