@echo off
setlocal
title Configure User Services

set "DemandServices=BcastDVRUserService BluetoothUserService CaptureService ConsentUxUserSvc CredentialEnrollmentManagerUserSvc DeviceAssociationBrokerSvc DevicePickerUserSvc DevicesFlowUserSvc MessagingService NPSMSvc P9RdrService PenService PimIndexMaintenanceSvc PrintWorkflowUserSvc UdkUserSvc UnistoreSvc UserDataSvc cbdhsvc"

set "AutoServices=CDPUserSvc OneSyncSvc WpnUserService webthreatdefusersvc"




:: -- Set the desired startup type: demand, disabled, auto, delayed-auto
set "STARTUP_TYPE=demand"


:: 2. Loop through each service prefix in the list
for %%p in (%DemandServices%) do (
    set "serviceFound=false"

    for /f "tokens=2" %%s in ('sc queryex type=service state=all ^| find "%%p_"') do (
        sc config "%%s" start=%STARTUP_TYPE% >nul
        set "serviceFound=true"
    )

    if "%serviceFound%"=="false" (
        echo   [NOT FOUND] No service matching "%%p_*" was found.
    )
    echo.
)

:: -- Set the desired startup type: demand, disabled, auto, delayed-auto
set "STARTUP_TYPE=auto"

:: 2. Loop through each service prefix in the list
for %%p in (%AutoServices%) do (
    set "serviceFound=false"

    for /f "tokens=2" %%s in ('sc queryex type=service state=all ^| find "%%p_"') do (
        sc config "%%s" start=%STARTUP_TYPE% >nul
        set "serviceFound=true"
    )

    if "%serviceFound%"=="false" (
        echo   [NOT FOUND] No service matching "%%p_*" was found.
    )
    echo.
)

echo ============================================================================
echo All tasks complete.
echo.
pause