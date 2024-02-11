*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Excel.Files
Library             RPA.Tables
Library             Collections
Library             RPA.PDF
Library             RPA.Archive


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders from Excel file
    FOR    ${order}    IN    @{orders}
        ${error}=    Set Variable    ${1}
        WHILE    ${error} == ${1}
            TRY
                Close the annoying modal
                Fill the form    ${order}
                Store the receipt as a PDF file    ${order}[Order number]
                Order another robot
                ${error}=    Set Variable    ${0}
            EXCEPT
                Reload Page
            END
        END
    END
    Zip the reciepts folder
    [Teardown]    Close Browser


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Download the Excel file
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True

Get orders from Excel file
    Download the Excel file
    ${orders}=    Read Table From Csv    orders.csv    header=True
    RETURN    ${orders}

Close the annoying modal
    Click Button    css:button.btn.btn-dark

Fill the form
    [Arguments]    ${order}
    Wait Until Page Contains Element    id:head
    Log    ${order}[Order number] ${order}[Address]
    Select From List By Value    head    ${order}[Head]
    ${body-id}=    Catenate    SEPARATOR=    id-body-    ${order}[Body]
    Select Radio Button    body    ${body-id}
    Input Text    css:input.form-control    ${order}[Legs]
    Input Text    address    ${order}[Address]

Preview the robot
    Wait Until Keyword Succeeds    3x    0.5 sec    Click Button    css:button.btn.btn-secondary
    Wait Until Element Is Visible    css:#robot-preview-image > img:nth-child(3)    1 sec
    Scroll Element Into View    css:footer

Take a screenshot of the robot
    [Arguments]    ${Order number}
    Preview the robot
    ${screen}=    Screenshot    robot-preview-image    ${OUTPUT_DIR}${/}screens${/}${Order number}.png
    RETURN    ${screen}

Store the receipt as a PDF file
    [Arguments]    ${Order number}
    Preview the robot
    ${screenshot}=    Take a screenshot of the robot    ${Order number}
    Wait Until Keyword Succeeds    3x    0.5 sec    Click Button    css:button.btn.btn-primary
    Wait Until Element Is Visible    id:receipt    1 sec
    ${receipt}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt}    ${OUTPUT_DIR}${/}orders${/}${Order number}.pdf
    Add Watermark Image To Pdf
    ...    ${screenshot}
    ...    ${OUTPUT_DIR}${/}orders${/}${Order number}.pdf
    ...    ${OUTPUT_DIR}${/}orders${/}${Order number}.pdf

Order another robot
    Wait Until Keyword Succeeds    3x    1 sec    Click Button    order-another

Zip the reciepts folder
    Archive Folder With Zip    ${OUTPUT_DIR}${/}orders    ${OUTPUT_DIR}${/}orders.zip
