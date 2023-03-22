*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Download the csv file
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Wait Until Page Contains Element    xpath://button[contains(text(),'OK')]
        Close the annoying modal
        Fill the form    ${row}
        Click Button    preview
        Wait Until Keyword Succeeds    10x    5sec    Submit order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        #Log    ${pdf}
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        #Log    ${screenshot}
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Wait Until Keyword Succeeds    3x    5sec    Order another
    END
    Create a ZIP file of receipt PDF files


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Download the csv file
    Download
    ...    https://robotsparebinindustries.com/orders.csv
    ...    overwrite=True
    ...    target_file=${OUTPUT DIR}${/}downloads

Get orders
    ${orders}=    Read table from CSV
    ...    path=${OUTPUT DIR}${/}downloads/orders.csv
    ...    header=True

    RETURN    ${orders}

Fill the form
    [Arguments]    ${order}    #pass argument order
    Log    ${order}[Order number]
    Select From List By Value    head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    xpath://input[contains(@placeholder,'legs')]    ${order}[Legs]
    Input Text    address    ${order}[Address]

Submit order
    Click Button    id:order
    # To make sure the order is submitted
    #Wait Until Element Does Not Contain    xpath://div[contains(@role,'alert')]    Error
    #Wait Until Page Does Not Contain Element    xpath://div[contains(@role,'alert')]
    Wait Until Page Contains Element    order-another

Order another
    Click Button    order-another

Close the annoying modal
    Click Button    xpath://button[contains(text(),'OK')]

Store the receipt as a PDF file
    [Arguments]    ${OrderNo}
    ${order_pdf_path}=    Set Variable    ${OUTPUT_DIR}${/}output${/}receipts${/}receipt-${OrderNo}.pdf
    Wait Until Element Is Visible    id:receipt
    ${order_receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${order_receipt_html}    ${order_pdf_path}
    RETURN    ${order_pdf_path}

Take a screenshot of the robot
    [Arguments]    ${OrderNo}
    ${order_png_path}=    Set Variable    ${OUTPUT_DIR}${/}output${/}images${/}screenshot_${OrderNo}.png
    Screenshot
    ...    id:robot-preview-image
    ...    ${order_png_path}
    RETURN    ${order_png_path}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    Add Watermark Image To Pdf    ${screenshot}    ${pdf}
    Close All Pdfs

    #${sales_results_html}=    Get Element Attribute    xpath://div[contains(@class,'container')]    outerHTML
    #Html To Pdf    ${sales_results_html}    ${OUTPUT_DIR}${/}output${/}results.pdf

    #Log    ${screenshot}

    #${files}=    Create List
    #...    ${screenshot}
    #Add Files To PDF    ${files}    ${pdf}
    #Close Pdf    ${pdf}
    #Add Watermark Image To PDF
    #...    image_path=${screenshot}
    #...    source_path=${OUTPUT_DIR}${/}output${/}results.pdf
    #...    output_path=${OUTPUT_DIR}${/}output${/}results.pdf

    #Close Pdf    ${pdf}

Create a ZIP file of receipt PDF files
    ${zip_file}=    Set Variable    ${OUTPUT_DIR}${/}output${/}receipts.zip
    Archive Folder With Zip    ${OUTPUT_DIR}${/}output${/}receipts    ${zip_file}    include=*.pdf
