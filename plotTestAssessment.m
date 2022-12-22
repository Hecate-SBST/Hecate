modelname = 'Pacemaker_3MD3_Group1';
titleStr = {'$Sensing$','$Heartbeat$','$No\_heartbeat$','$Mode$'};
Hecate_Mode = 3;
Hecate_delayOff = 0;
Hecate_delayOn = 0;
Hecate_HeartFail = 40;

out = sim(modelname);

%% Plot of ATR_CMP_DETECT
t = out.tout;
detect = out.YT.signals(4).values;

figure(1)
hold on
plot(t,detect,'k')
set(gca,'FontSize',16)
ylim([-0.2,1.2])
yticks([0,1])
yticklabels({'$False$','$True$'})
xlabel('$Time~[s]$','FontSize',20,'Interpreter','latex')
title('$ATR\_CMP\_DETECT$','FontSize',20,'Interpreter','latex')
set(gcf,'Position',[0,400,600,300])

saveas(gcf,'PM_ATR_CMP_DETECT.eps','eps')

%% Plot of Test Assessment results
assSet = sltest.getAssessments(modelname);

for idx = 1:4
    ass = get(assSet,idx);
    t = ass.Values.Time;
    ass = ass.Values.Data;
    
    t_P = t(ass == 0);
    t_F = t(ass == 1);
    t_U = t(ass == -1);
    
    figure(idx+1)
    hold on
    plot(t_P,zeros(size(t_P)),'ks')
    plot(t_F,ones(size(t_F)),'ko')
    plot(t_U,-ones(size(t_U)),'k*')
    set(gca,'FontSize',16)
    ylim([-1.3,1.3])
    yticks([-1,0,1])
    yticklabels({'$Untested$','$Pass$','$Fail$'})
    xlabel('$Time~[s]$','FontSize',20,'Interpreter','latex')
    % ylabel('$Status$','FontSize',20,'Interpreter','latex')
    title(titleStr{idx},'FontSize',20,'Interpreter','latex')
    
    set(gcf,'Position',[0,400,600,300])
    saveas(gcf,['PM_results_',num2str(idx),'.eps'],'eps')
end
