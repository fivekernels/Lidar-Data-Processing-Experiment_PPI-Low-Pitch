% angle_arr = 0:12:360;                % 扫描角度数组 正弦拟合横坐标
count_angle = 65;
angleValid_arr = 0:12:180;               % 扫描角度数组 正弦拟合横坐标
% count_angleValid = size(angleValid_arr, 2);
count_angleValid = 65;
count_time = size(struct_oriVAD, 2); % 数据组数(时间个数)
height_arr = 75:15:840;              % 高度数组
count_height = size(height_arr, 2);  % 高度个数

const_header_reportDrop_time = 1;
const_header_reportDrop_height = 2;
const_header_reportDrop_angle = 3;
const_header_reportDrop_delta = 4;

axis_time = repmat("",1, count_time);
axis_height = repmat("",1, count_height);
drawdata = NaN(count_height, count_time);
drawdata_SNR = NaN(count_height, count_time);
for i = 1:count_time
    % 时间轴序列
    axis_time(i) = sprintf("%d:%d:%.3f", struct_calVAD(i).time_hour, ...,
                                       struct_calVAD(i).time_minute, ...,
                                       struct_calVAD(i).time_second);

    
%     % sin 风速
%     drawdata(:, i) = struct_calVAD(i).windspeed(:, const_header_caldata_windspeed);
    %sin 风向
    drawdata(:, i) = struct_calVAD(i).windspeed(:, const_header_caldata_windAngle);

    drawdata_SNR(:, i) = struct_calVAD(i).windspeed(:, const_header_caldata_SNR);
%     % 垂直速度
%     drawdata(:, i) = synSpeed_struct(i).cal_data(:, const_header_caldata_speedUp);
%     drawdata_SNR(:, i) = synSpeed_struct(i).cal_data(:, 4);
end

% 去信噪比
for row_i = 1:size(drawdata, 1)
    for column_i = 1:size(drawdata, 2)
        if (drawdata_SNR(row_i, column_i)<=5)
            drawdata(row_i, column_i) = NaN;
%             dispstr = sprintf("(%d, %d)", row_i, column_i);
%             disp(dispstr);
        end
    end
end

h = imagesc(drawdata);
set(gca,'YDir','normal');
set(h,'alphadata',~isnan(drawdata));
colormap(jet);
colorbar;
% 设置坐标
set(gca,'xtick',1:20:count_time);
set(gca,'xticklabel',axis_time(1, 1:20:count_time));
set(gca, 'XTickLabelRotation', 310);
set(gca,'ytick',1:5:count_height);
set(gca,'yticklabel',height_arr(1, 1:5:count_height));
xlabel('2021-08-06');
ylabel('Height(m)');
% title('v(horizontal) SNR>15');
title('alpha SNR>5');


