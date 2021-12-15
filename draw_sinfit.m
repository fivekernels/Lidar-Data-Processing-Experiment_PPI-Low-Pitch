function struct_calVAD = draw_sinfit(struct_oriVAD)

% angle_arr = 0:12:360;                % 扫描角度数组 正弦拟合横坐标
count_angle = 65;
% angleValid_arr = 0:12:180;               % 扫描角度数组 正弦拟合横坐标
% count_angleValid = size(angleValid_arr, 2);
count_angleValid = 65;
count_time = size(struct_oriVAD, 2); % 数据组数(时间个数)
height_arr = 75:15:840;              % 高度数组
count_height = size(height_arr, 2);  % 高度个数

const_header_reportDrop_time = 1;
const_header_reportDrop_height = 2;
const_header_reportDrop_angle = 3;
const_header_reportDrop_delta = 4;
reportDrop_arr = NaN(floor(count_time*count_height/3), 4); % 时间 高度 角度 值

%计算结构体定义 时间 高度 角度
const_header_caldata_windspeed = 1;
const_header_caldata_windAngle = 2;
const_header_caldata_SNR = 3;
% 计算结构体预分配
field_time_ymd = 'time_ymd';
field_time_hour = 'time_hour';
field_time_minute = 'time_minute';
field_time_second = 'time_second';
field_pitch = 'pitch'; % 仰角 [0-360]
field_azimuth = 'azimuth'; % 朝向
field_windspeed = 'windspeed'; % 高度 \ [0-360]
field_windSNR = 'windSNR'; % 高度 \ [0-360]
struct_calVAD = struct( field_time_ymd, NaN, ...,
                     field_time_hour, NaN, ...,
                     field_time_minute, NaN, ...,
                     field_time_second, NaN, ...,
                     field_windspeed, NaN(count_height, 3) ..., % 风速 风向 信噪比
                   );
struct_calVAD = repmat( struct_calVAD, [1 count_time] );

% % 画圆圈
% index_time = 1;
% angle_arr = struct_oriVAD(index_time).azimuth;                % 扫描角度数组 正弦拟合横坐标
% % angle_arr = [struct_oriVAD(index_time).azimuth, 180 + struct_oriVAD(index_time+1).azimuth,];                % 扫描角度数组 正弦拟合横坐标
% [r,theta] = meshgrid(height_arr,deg2rad(angle_arr));
% x = r.*cos(theta);
% y = r.*sin(theta);
% z = struct_oriVAD(index_time).windspeed';
% % z = [struct_oriVAD(index_time).windspeed, struct_oriVAD(index_time+1).windspeed]';
% surf(x,y,z,'LineStyle','none');
% colormap('jet');
% % caxis([-5 5])
% colorbar;
% view(2);

% 遍历剔除
offWarningId = 'curvefit:prepareFittingData:removingNaNAndInf'; % 关闭警告
warning('off',offWarningId);
count_drop_total = 0;
for index_time = 1:count_time
    angleValid_arr = struct_oriVAD(index_time).azimuth;
    for index_height = 1:count_height
        % 循环删值
%         windspeedOri_arr = struct_oriVAD(index_time).windspeed(index_height, :);
        windspeedOriValid_arr = struct_oriVAD(index_time).windspeed(index_height, 1:count_angleValid);
%         windspeedOriValid_arr(count_angleValid+1:count_angle) = NaN;
        times_drop = 0; % 删除次数
        while 1
            % scatter(axis_angle, axis_value);
            if(sum(~isnan(windspeedOriValid_arr), 2)<3)
                disp("err not enough valid point");
                break;
            end
            [fitresult, gof] = fit_a_Sind_x_c_d(angleValid_arr, windspeedOriValid_arr); % 拟合
            % 计算误差
            delta_sinfit = NaN(1, count_angleValid); %误差数组
            for i = 1:count_angleValid
                delta_sinfit(i) = abs( fitresult(angleValid_arr(i)) - windspeedOriValid_arr(i) );
            end
            avg_deltaSinfit = mean(delta_sinfit);
            sigma_deltaSinfit = std(delta_sinfit);
            k_sigma = 3;
            count_dropSingleTH = 0;
            for i = 1:count_angleValid
                if abs( delta_sinfit(i) - avg_deltaSinfit ) > k_sigma * sigma_deltaSinfit
                    fprintf("(time=%d, height=%d) drop i=%d, delta=%f\n",index_time, index_height, i, delta_sinfit(i));
                    windspeedOriValid_arr(i) = NaN;
                    count_dropSingleTH = count_dropSingleTH + 1;
                    count_drop_total = count_drop_total + 1;
                    % 存报表
                    reportDrop_arr(count_drop_total, const_header_reportDrop_time) = index_time;
                    reportDrop_arr(count_drop_total, const_header_reportDrop_height) = index_height;
                    reportDrop_arr(count_drop_total, const_header_reportDrop_angle) = i;
                    reportDrop_arr(count_drop_total, const_header_reportDrop_delta) = delta_sinfit(i);
                end
            end
            if count_dropSingleTH == 0
                break
            end
            times_drop = times_drop + 1;
            if(times_drop>1)
                disp(times_drop);
            end
        end % while 1
        
        % 计算风速风向
        % 风速
        struct_calVAD(index_time).windspeed(index_height, const_header_caldata_windspeed) = abs(fitresult.a);
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
        struct_calVAD(index_time).windspeed(index_height, const_header_caldata_windAngle) = windAngle;
        % 信噪比
        struct_calVAD(index_time).windspeed(index_height, const_header_caldata_SNR) = min(struct_oriVAD(index_time).windSNR(index_height, 1:count_angleValid));
        
    end % end index_height
end % end index_time
% 赋值时间
for index_time = 1:count_time
    struct_calVAD(index_time).time_ymd = struct_oriVAD(index_time).time_ymd;
    struct_calVAD(index_time).time_hour = struct_oriVAD(index_time).time_hour;
    struct_calVAD(index_time).time_minute = struct_oriVAD(index_time).time_minute;
    struct_calVAD(index_time).time_second = struct_oriVAD(index_time).time_second;
end

end

% % 连续时间同一高度
% timeCount = size(struct_oriVAD, 2);
% drawdata = NaN(1, timeCount);
% for timeIndex = 1:timeCount
%     drawdata(timeIndex) = struct_oriVAD(timeIndex).windspeed(1, 31);
% end
% hold on;
% plot(drawdata);


% % 强行imagesc
% % 极坐标转换
% angleValid_arr = 0:12:360;
% height_arr = 30:15:2880; % 高度数组
% height_arr = 3.0:1.5:288.0; % 高度数组
% xydata = NaN( height_arr(size(height_arr, 2))*2 + 2);
% for angleIndex = 1:size(angleValid_arr, 2)
%     for heightIndex = 1:size(height_arr, 2)
%         angleIndex
%         heightIndex
%         x_value = round( cosd(angleValid_arr(angleIndex)) * height_arr(heightIndex) ) + ceil(size(xydata,1)/2) + 1;
%         y_value = round( sind(angleValid_arr(angleIndex)) * height_arr(heightIndex) ) + ceil(size(xydata,1)/2) + 1;
%         xydata(x_value, y_value) = struct_oriVAD(1).windspeed(heightIndex, angleIndex);
%     end
% end
% xIndex = 1;
% while xIndex <=size(xydata, 2) %删列
%     xIndex
%     if isnan(xydata(:, xIndex))
%         xydata(:, xIndex) = [];
%     else
%         xIndex = xIndex+1;
%     end
% end
% 
% yIndex = 1;
% while yIndex <=size(xydata, 1) %删行
%     yIndex
%     if isnan(xydata(yIndex, :))
%         xydata(yIndex, :) = [];
%     else
%         yIndex = yIndex+1;
%     end
% end

% 代码拟合  有点二逼。
% solution(axis_angle, axis_value);
% function solution(xdata, ydata)
% % clc;clear
% x = [2 10 5 4] ;
% % xdata = sort(rand(1,100)) ;
% % ydata = x(1)*sin(x(2)*xdata+x(3))+x(4) ;
% x_est = lsqcurvefit(@(x,xdata) myfun(x,xdata),[2 2 2 2],xdata,ydata);
% plot(xdata,ydata,'b-') ;
% hold on
% plot(xdata,myfun(x_est,xdata),'g-') ;
% legend({'观测值','拟合值'}) ;
% end
% 
% function F = myfun(x,xdata)
% F = x(1)*sin(x(2)*xdata+x(3))+x(4) ;
% end


% h = imagesc(-floor(size(xydata, 2)/2):ceil(size(xydata, 2)/2),-floor(size(xydata, 1)/2):ceil(size(xydata, 1)/2),xydata);
% set(gca,'xtick',1:100:size(ori_struct, 2));
% set(gca,'xticklabel',axis_time(1, 1:100:size(ori_struct, 2)));
% set(gca,'ytick',1:10:size(height_arr, 2));
% set(gca,'yticklabel',height_arr(1, 1:10:size(height_arr, 2)));
% colormap(jet);
% set(h,'alphadata',~isnan(xydata));
% set(gca,'YDir','normal');
% colorbar;
% xlabel('2021-08-06');
% ylabel('Height(m)');
% title('v(horizontal) SNR>15');