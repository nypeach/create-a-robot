# +
*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

Library           RPA.Browser.Selenium
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.Dialogs
Library           RPA.Robocloud.Secrets
# -


*** Keywords ***
Get and Log the Vault Secret Values
    ${secret}=    Get Secret    credentials
    Add icon      Success
    Add heading   Your username is ${secret}[username] and password is ${secret}[password]. Note: in real robots, you should NOT keep secrets in your project file. This is just for demonstration purposes :)
    Run dialog    title=Success

*** Keywords ***
Get Order.csv URL
    # Add text input    orderurl     What is the URL of the Orders csv?  placeholder=https://robotsparebinindustries.com/orders.csv
    Add text input    orderurl
    ...    label=What is the URL of the Orders csv?
    ...    placeholder=https://robotsparebinindustries.com/orders.csv
    Add text    Type in https://robotsparebinindustries.com/orders.csv
    ${response}=    Run dialog
    [Return]    ${response.orderurl}

*** Keywords ***
Open the Robot Order Website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order


*** Keywords ***
Get Orders
    ${orderurl}=    Get Order.csv URL
    Download    ${orderurl}    overwrite=True
    ${orders}=    Read Table From Csv    orders.csv   header=True
    [Return]    ${orders}

*** Keywords ***
Close the Annoying Modal
    Click Button    css:button.btn.btn-dark

*** Keywords ***
Fill the Order Form
    [Arguments]    ${order}
    Select From List By Value    head   ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    css:input.form-control    ${order}[Legs]
    Input Text    id:address    ${order}[Address]

*** Keywords ***
Preview the Robot
    Click Button    id:preview

# +
*** Keywords ***
Submit the Order and Keep Checking Until Success
    Wait Until Keyword Succeeds    10x    0.1 sec    Submit the Order

Submit the Order
    Click Button    id:order
    Wait Until Page Contains Element    id:order-completion
# -

*** Keywords ***
Store the Receipt as a PDF
    [Arguments]    ${pdfname}
    Wait Until Element Is Visible    id:receipt
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${CURDIR}${/}output${/}receipts${/}${pdfname}.pdf

*** Keywords ***
Take a Screenshot of the Robot
    [Arguments]   ${imagename}
    Screenshot    id:robot-preview-image    ${CURDIR}${/}output${/}images${/}${imagename}.png

*** Keywords***
Embed the Robot Screenshot to the Receipt PDF file
    [Arguments]    ${ordernum}
    #Open Pdf
    Add Watermark Image To Pdf
    ...    output/images/${ordernum}.png
    ...    output/receipts/${ordernum}.pdf
    ...    output/receipts/${ordernum}.pdf


*** Keywords ***
Order Another Robot
    Click Button    id:order-another


*** Keywords ***
Close Robot Order Browser
    Close the Annoying Modal
    Close Browser

*** Keywords ***
Create a Zip File of the Receipts
    Archive Folder With Zip    output/receipts/    receipts.zip

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Get and Log the Vault Secret Values
    Open the Robot Order Website
    ${orders}=    Get Orders
    FOR    ${order}    IN    @{orders}
        Close the Annoying Modal
        Fill the Order Form    ${order}
        Preview the Robot
        Submit the Order and Keep Checking Until Success
        ${pdf}=    Store the Receipt as a PDF    ${order}[Order number]
        ${screenshot}=    Take a Screenshot of the Robot    ${order}[Order number]
        Embed the Robot Screenshot to the Receipt PDF file    ${order}[Order number]
        Order Another Robot
    END
    Close Robot Order Browser
    Create a Zip File of the Receipts

