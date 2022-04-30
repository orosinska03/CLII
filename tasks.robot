*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archieve of the receipts and the images.
Library           OperatingSystem
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.HTTP
Library           RPA.PDF
Library           RPA.Robocorp.Vault
Library           RPA.Tables
Library           RPA.Archive
Library           RPA.Dialogs

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Prepare the process directories
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}
        ${screenshot}=    Take a screenshot of the robot    ${row}
        Embed the robot screenshot to the receipt PDF file    ${row}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    [Teardown]    Close Browser

*** Keywords ***
Prepare the process directories
    Remove Files    ${OUTPUT_DIR}${/}*.pdf    missing_ok=${TRUE}
    Remove Files    ${OUTPUT_DIR}${/}*.png    missing_ok=${TRUE}
    Remove Files    ${OUTPUT_DIR}${/}*.zip    missing_ok=${TRUE}
    Remove Files    ${OUTPUT_DIR}${/}Receipts${/}*.pdf    missing_ok=${TRUE}

Open the robot order website
    ${secret}=    Get Secret    url
    Open Available Browser    ${secret}[robot-order-site]

Get orders
    Add Heading    Hey, let's get ordering those robots!
    Add text input    orders_address
    ...    label=Where can we find the order list?
    ...    placeholder=Enter orders.csv address
    ${result}    Run Dialog
    Download    ${result.orders_address}    overwrite=True
    ${table}    Read table from CSV    orders.csv
    [Return]    ${table}

Close the annoying modal
    Wait Until Element Is Visible    class:alert-buttons
    Click Button    css:button.btn.btn-dark

Fill the form
    [Arguments]    ${row}
    Select From List By Value    head    ${row}[Head]
    Click Element    id-body-${row}[Body]
    Input Text    class:form-control    ${row}[Legs]
    Input Text    address    ${row}[Address]

Preview the robot
    Click Button    preview
    Wait Until Element Is Visible    robot-preview

Submit the order
    Click Button    order

Store the receipt as a PDF file
    [Arguments]    ${row}
    Wait Until Element Is Visible    id:receipt
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${OUTPUT_DIR}${/}receipt-${row}[Order number].pdf

Take a screenshot of the robot
    [Arguments]    ${row}
    Screenshot    robot-preview-image    ${OUTPUT_DIR}${/}receipt-${row}[Order number].png

Go to order another robot
    Click Button    order-another
    Wait Until Element Is Visible    class:alert-buttons

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${row}
    ${files}=    Create List    ${OUTPUT_DIR}${/}receipt-${row}[Order number].png
    ...    ${OUTPUT_DIR}${/}receipt-${row}[Order number].pdf
    Add Files To Pdf    ${files}    ${OUTPUT_DIR}${/}Receipts${/}receipt-${row}[Order number].pdf

Create a ZIP file of the receipts
    Archive Folder With Zip    ${OUTPUT_DIR}${/}Receipts
    ...    ${OUTPUT_DIR}${/}receipt-pdf-archive.zip
    ...    recursive=${TRUE}    include=*.pdf

Close Browser
    Close Browser
