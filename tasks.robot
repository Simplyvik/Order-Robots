*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium
Library             RPA.Tables
Library             RPA.HTTP
Library             Dialogs
Library             RPA.PDF
Library             Collections
Library             RPA.Archive
Library             RPA.RobotLogListener


*** Variables ***
${localCsv}         localCsv.csv
@{PDFs}             @{EMPTY}
${OUTPUT_DIR}       output


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Download File
    ${collectionOfOrders}=    Get orders
    Loop orders    ${collectionOfOrders}
    ZIP files


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    Click Element When Visible    css:.btn.btn-danger

Download file
    Download    https://robotsparebinindustries.com/orders.csv    ${localCsv}    overwrite=${True}

Get orders
    @{getdata}=    Read table from CSV    ${localCsv}
    RETURN    ${getdata}

Loop orders
    [Arguments]    ${localData}
    FOR    ${row}    IN    @{localData}
        Log    ${row}
        Fill the form and order    ${row}
    END

Fill the form and order
    [Arguments]    ${localrow}
    Select From List By Index    id:head    ${localrow}[Head]
    ${selectedRadioButton}=    Catenate    SEPARATOR=-    id-body    ${localrow}[Body]
    Select Radio Button    body    ${selectedRadioButton}
    Input Text    css:input[placeholder='Enter the part number for the legs']    ${localrow}[Legs]
    Input Text    id:address    ${localrow}[Address]
    Preview the order
    Submit The Order
    Verify order
    ${pdf}=    Create and store the receipt as a PDF file    ${localrow}[Order number]
    ${robot_image}=    Take a screenshot of the robot    ${localrow}[Order number]
    Embed the robot screenshot to the receipt PDF file    ${robot_image}    ${pdf}
    Append To List    ${PDFs}    ${pdf}
    Enter new order

Preview the order
    Click Button    id:preview

Submit the order
    WHILE    True
        TRY
            Wait Until Keyword Succeeds    3x    1s    Click Button    id:order
            Sleep    1s
            Page Should Not Contain Element    css:.alert.alert-danger
            BREAK
        EXCEPT
            Log    Failed to submit an order
        END
    END

Verify order
    TRY
        Wait Until Page Contains Element    id:receipt
    EXCEPT
        Log    Should not happen
    END

Create and store the receipt as a PDF file
    [Arguments]    ${local_order}
    ${local_PDF}=    Catenate    SEPARATOR=    ${OUTPUT_DIR}${/}    receipt_order_nr_    ${local_order}    .pdf
    ${order_receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${order_receipt_html}    ${local_PDF}
    RETURN    ${local_PDF}

Take a screenshot of the robot
    [Arguments]    ${local_order}
    ${local_image}=    Catenate    SEPARATOR=    ${OUTPUT_DIR}${/}    image_robot_nr_    ${local_order}    .png
    Screenshot    id:robot-preview-image    ${local_image}
    RETURN    ${local_image}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${Local_screenshot}    ${local_pdf}
    @{list_of_local_scenshot}=    Create List    ${Local_screenshot}
    Open Pdf    ${local_pdf}
    Add Files To Pdf    ${list_of_local_scenshot}    ${local_pdf}    True
    # Close Pdf    ${local_pdf}

Enter new order
    Click Button    id:order-another
    Click Element When Visible    css:.btn.btn-danger

ZIP files
    Archive Folder With Zip    ${OUTPUT_DIR}${/}    ${OUTPUT_DIR}${/}Order_archive.zip    include=*.pdf
