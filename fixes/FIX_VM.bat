@echo off
echo HyperV
sc config TermService start=Demand
sc start TermService

echo VMWare
sc config PlugPlay start= auto
sc start PlugPlay
sc config DispBrokerDesktopSvc start= demand
sc start DispBrokerDesktopSvc
sc config DisplayEnhancementService start= demand
sc start DisplayEnhancementService
sc start VMTools

exit