angle_arr = 0:12:360;               % 扫描角度数组 正弦拟合横坐标
count_time = size(struct_oriVAD, 2); % 数据组数(时间个数)
height_arr = 30:15:2880;             % 高度数组
count_height = size(height_arr, 2);  % 高度个数
axis_value = NaN(count_time, 31);    % 正弦拟合源数值  %需要简化

%计算结构体定义 时间 高度 角度
const_header_caldata_windspeed = 1;
const_header_caldata_windAngle = 2;
const_header_caldata_SNR = 3;
% 计算结构体预分配
cal_struct = struct( field_time_ymd, NaN, ...,
                     field_time_hour, NaN, ...,
                     field_time_minute, NaN, ...,
                     field_time_second, NaN, ...,
                     field_windspeed, NaN(length(height_arr), 3) ..., % 风速 风向 信噪比
                   );
cal_struct = repmat( cal_struct, [1 count_time] );

for timeIndex = 1:count_time
    disp(timeIndex);
    for heightIndex = 1:count_height
        % disp(heightIndex);
        axis_value(timeIndex, :) = struct_oriVAD(timeIndex).windspeed(heightIndex, :);
        hold on;
        [fitresult, gof] = fit_a_Sind_x_c_d(angle_arr, axis_value(timeIndex, :)); % 正弦拟合
        % 风速
        cal_struct(timeIndex).windspeed(heightIndex, const_header_caldata_windspeed) = abs(fitresult.a);
        % 风向
        windAngle = 90 - fitresult.c;
        if fitresult.a < 0
            windAngle = windAngle + 180;
        end
        while windAngle >= 360
            windAngle = windAngle - 360;
        end
        while windAngle < 0
            windAngle = windAngle + 360;
        end
        cal_struct(timeIndex).windspeed(heightIndex, const_header_caldata_windAngle) = windAngle;
        % 信噪比
        cal_struct(timeIndex).windspeed(heightIndex, const_header_caldata_SNR) = min(struct_oriVAD(timeIndex).windSNR(heightIndex, :));
    end
end