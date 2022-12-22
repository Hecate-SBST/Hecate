close all;
%plot the RQ3 input, output, and hecate parameters
style = {'-','--',':','-.'};
%% plot urban cycle, original speed
figure;
grid on;
hold on
plot(UrbanCycle3.time, UrbanCycle3.SpdKph, 'Color', 'k', 'LineStyle', style{1}, 'LineWidth', 2)
xlim([0, 400])
%ylim([-0.2,1.2])
%yticks([0, 1])
%yticklabels({'$False$','$True$'})
set(gca,'TickLabelInterpreter','latex','FontSize',16)
set(gcf,'color','w');
xlabel('$Time~[s]$','Interpreter','latex','FontSize',20)
ylabel('$Original~Speed~[kph]$','Interpreter','latex','FontSize',20)
hold off

%% plot the hecate parameters perturbation
figure;
grid on;
hold on;
hp1 = ones(101,1)*Hecate_param1;
hp2 = ones(100,1)*Hecate_param2;
hp3 = ones(100,1)*Hecate_param3;
hp4 = ones(100,1)*Hecate_param4;
hp=[hp1;hp2;hp3;hp4];

plot([1:401], hp, 'Color', 'k', 'LineStyle', style{1}, 'LineWidth', 2)

xlim([0, 400])
%ylim([-0.2,1.2])
%yticks([0, 1])
%yticklabels({'$False$','$True$'})
set(gca,'TickLabelInterpreter','latex','FontSize',16)
set(gcf,'color','w');
xlabel('$Time~[s]$','Interpreter','latex','FontSize',20)
ylabel('$Perturbations~[kph]$','Interpreter','latex','FontSize',20)
hold off;

%% plot sum of original and perturbed
figure;
grid on;
hold on;
plot(out.sum.Time,out.sum.Data, 'Color', 'k', 'LineStyle', style{1}, 'LineWidth', 2)

xlim([0, 400])
%ylim([-0.2,1.2])
%yticks([0, 1])
%yticklabels({'$False$','$True$'})
set(gca,'TickLabelInterpreter','latex','FontSize',16)
set(gcf,'color','w');
xlabel('$Time~[s]$','Interpreter','latex','FontSize',20)
ylabel('$Perturbed~Speed~[kph]$','Interpreter','latex','FontSize',20)
hold off;
%% plot the speed_o_delta variable to see where it falsifies

figure;
grid on;
hold on;
plot(out.speed_o_delta.Time, out.speed_o_delta.Data, 'Color', 'k', 'LineStyle', style{1}, 'LineWidth', 2)
%yline([1,1.5],'--',{'1','1.5'});
plot([0,1],[1.5,1.5],'--', 'LineWidth',2,'Color', 'k')
plot([1,1,1,1,1,1,1,1,1,1]','--','LineWidth', 2,'Color', 'k');
xlim([0,10])
ylim([0,4])
%yticks([0, 1])
%yticklabels({'$False$','$True$'})
set(gca,'TickLabelInterpreter','latex','FontSize',16)
set(gcf,'color','w');
xlabel('$Time~[s]$','Interpreter','latex','FontSize',20)
ylabel('$Speed\_o\_Delta ~[kph]$','Interpreter','latex','FontSize',20)
hold off;