if ii == 0
    SettingPM
else
    Hecate_delayEnd = 2;
    Hecate_delayOn = -0.8;
    Hecate_delayOff = 0.1;
end

sim(model,[0, simulationTime]);
style = {'-','--',':','-.'};

figure(1)
grid on
hold on
if ii == 0
    plot(ATR_CMP_DETECT.Time, ATR_CMP_DETECT.Data, 'Color', 'k', 'LineStyle', style{ii+1}, 'LineWidth', 2)
    xlim([0, simulationTime])
    ylim([-0.2,1.2])
    yticks([0, 1])
    yticklabels({'$False$','$True$'})
    set(gca,'TickLabelInterpreter','latex','FontSize',16)
    xlabel('$Time~[s]$','Interpreter','latex','FontSize',20)
    ylabel('$ATRCmpDetect$','Interpreter','latex','FontSize',20)
else
    plot(ATR_CMP_DETECT.Time, ATR_CMP_DETECT.Data, 'Color', 'k', 'LineStyle', style{ii+1})
end

ii = ii+1;