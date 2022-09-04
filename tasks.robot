*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library    RPA.Browser.Selenium    auto_close=${FALSE}
Library    RPA.Tables
Library    OperatingSystem
Library    RPA.PDF
Library    RPA.Archive
Library    RPA.Robocorp.Vault
Library    RPA.Dialogs
Library    RPA.HTTP

*** Variables ***

*** Tasks ***
Download all orders and zip
    Download orders csv file from website
    Fill data to orders website
    Ask day from assistant and store input as variable
    Read data from local Vault and store data as variable
    Zip all pdf-files
    Rename zip file
    [Teardown]    Clean files from computer and close browser 

    # Upload all data developer own public GitHub reposition(include vault JSON)

*** Keywords ***
Download orders csv file from website
    Download    https://robotsparebinindustries.com/orders.csv    ${OUTPUT_DIR}${/}    overwrite=TRUE

Fill data to orders website
    Open Available Browser    about:blank
    ${table}=    Read table from CSV    ${OUTPUT_DIR}${/}orders.csv    True        dialect=excel
    FOR    ${data}    IN    @{table}
        Go To    https://robotsparebinindustries.com/#/robot-order
        Click Button    css:button.btn.btn-warning
        Wait Until Page Contains Element    id:root
        Select From List By Value    head    ${data["Head"]}    
        Click Element    id-body-${data["Body"]}
        Input Text    css=[id^="166"]    ${data["Legs"]}
        Input Text    address    ${data["Address"]}
        Click Button    preview
        Wait Until Keyword Succeeds    10 times    1 sec    Wait for order button
        # Take screenshot each robot and save to png
        Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}robot_preview.png
        # Save each order to pdf
        ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
        Html To Pdf    ${receipt_html}<br><br><center><img src='${OUTPUT_DIR}${/}robot_preview.png' width='200' heigth='200'/></center>    ${OUTPUT_DIR}${/}zip/receipt${data["Order number"]}.pdf
    END

Wait for order button
    Click Button    order
    Wait Until Element Is Visible    receipt

Ask day from assistant and store input as variable
    Add icon    Warning
    Add heading    I need to know todays date (only date). Can you answer for that?
    Add text input    What is The Date Today? 
    ...    label=Date
    ...    placeholder=Excaple: 15
    ...    rows=1
    ${result}=    Run dialog    height=400    width=400
    Log    ${result}
    Set Test Variable    ${userDateInput}    ${result["What is The Date Today?"]}

Read data from local Vault and store data as variable
    ${secret}=    Get Secret    huuhaa
    Set Test Variable    ${s1}    ${secret}[month]${secret}[year]

Zip all pdf-files
    Archive Folder With Zip  ${OUTPUT_DIR}${/}zip  ${OUTPUT_DIR}${/}zip/all_orders.zip

Rename zip file
    Move File   ${OUTPUT_DIR}${/}zip/all_orders.zip    ${OUTPUT_DIR}${/}zip/all_orders_${userDateInput}${s1}.zip    

Clean files from computer and close browser
    Remove File    ${OUTPUT_DIR}${/}orders*
    Remove File    ${OUTPUT_DIR}${/}robot_preview*
    Remove File    ${OUTPUT_DIR}${/}zip/receipt*
    Close Browser
