*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium
Library             RPA.HTTP
Library             RPA.Tables
Library             XML
Library             RPA.PDF
Library             RPA.FileSystem
Library             RPA.Archive
Library             RPA.RobotLogListener
Library             RPA.Assistant
Library             OperatingSystem


*** Variables ***
${GLOBAL_RETRY_AMOUNT}=         10x
${GLOBAL_RETRY_INTERVAL}=       0.5s


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    # Mute Run On Failure    Open the robot order website
    ${input_url}=    User Input task
    Open the robot order website    ${input_url}
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        # Go To    https://robotsparebinindustries.com/#/robot-order
        Close the annoying modal
        Fill the form    ${row}
        # Sleep    1
        Download and store the order receipt as a PDF file    ${row}
        Order another Robot
    END
    Archive output PDFs
    [Teardown]    Close RobotSpareBin Browser


*** Keywords ***
Open the robot order website
    [Arguments]    ${URL}
    # // ToDo: Implement your keyword here
    # ${URL}=    Set Variable    https://robotsparebinindustries.com/#/robot-order
    Open Available Browser    ${URL}

Download the orders file
    ${DOWNLOAD_URL}=    Set Variable    https://robotsparebinindustries.com/orders.csv
    Download    ${DOWNLOAD_URL}    target_file=${OUTPUT_DIR}    overwrite=${True}

Get orders
    [Documentation]    Download the orders file, read it as a table, and return the result
    Download the orders file

    # * Read CSV as a table and return the result
    ${orders}=    Read table from CSV    ${OUTPUT_DIR}${/}orders.csv
    # Log To Console    ${orders}
    RETURN    ${orders}

Close the annoying modal
    Click Button    OK

Fill the form
    [Arguments]    ${row}
    Select From List By Value    id:head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    # Input Text    css:input.form-control    ${row}[Legs]
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${row}[Legs]
    Input Text    id:address    ${row}[Address]

    Preview the robot
    Submit the order util success

Preview the robot
    Click Button    id:preview

Submit the order and check
    Click Button    Order
    # Wait Until Keyword Succeeds에서 사용하기 위해 확인하는 절차 추가
    ${element_exist}=    Is Element Visible    id:receipt
    # 조건이 참이 아닐 경우 에러 발생
    # Should Be True    ${element_exist}    raise exception!
    IF    ${element_exist} == $False    Fail    # raise

Submit the order util success
    # Wait Until Keyword Succeeds는 인수로 들어오는 키워드의 에러발생 여부를 탐지한다
    # Wait Until Keyword Succeeds <- Built in
    Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${GLOBAL_RETRY_INTERVAL}    Submit the order and check

Download and store the order receipt as a PDF file
    [Arguments]    ${row}
    ${order_number}=    Set Variable    ${row}[Order number]
    ${pdf}=    Store the order receipt as a PDF file    ${order_number}
    ${screenshot}=    Take a screenshot of the robot    ${order_number}
    Embed the robot screenshot to the receipt PDF file    ${order_number}    ${screenshot}    ${pdf}

Store the order receipt as a PDF file
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    id:receipt
    # ? [ WARN ] Keyword 'Get Element Attribute' found both from a custom library 'RPA.Browser.Selenium' and a standard library 'XML'.
    # ? The custom keyword is used. To select explicitly, and to get rid of this warning, use either 'RPA.Browser.Selenium.Get Element Attribute' or 'XML.Get Element Attribute'.
    ${order_receipt_html}=    RPA.Browser.Selenium.Get Element Attribute    id:receipt    outerHTML
    # Ensure a unique name
    ${file_name}=    Set Variable    0${order_number}_order_receipt.pdf
    ${file_path}=    Set Variable    ${OUTPUT_DIR}${/}order_receipt${/}${file_name}
    Html To Pdf    ${order_receipt_html}    ${file_path}    # make automatically "robot_preview_image" dir
    RETURN    ${file_path}

Take a screenshot of the robot
    [Arguments]    ${order_number}
    # Ensure a unique name
    ${file_name}=    Set Variable    0${order_number}_robot_preview_image.png
    ${file_path}=    Set Variable    ${OUTPUT_DIR}${/}robot_preview_image${/}${file_name}
    Screenshot    id:robot-preview-image    ${file_path}    # make automatically "robot_preview_image" dir
    RETURN    ${file_path}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${order_number}    ${screenshot}    ${pdf}
    # Open Pdf    ${pdf}
    # Ensure a unique name
    ${file_name}=    Set Variable    0${order_number}_result.pdf
    RPA.FileSystem.Create Directory    ${OUTPUT_DIR}${/}result
    ${file_path}=    Set Variable    ${OUTPUT_DIR}${/}result${/}${file_name}
    # ! ValueError: Argument 'files' got value
    # Add Files To Pdf    @{files}    ${file_path} -> 에러 발생
    # 선언에서는 @, 참조에서는 $ ?
    Add Watermark Image To Pdf
    ...    image_path=${screenshot}
    ...    source_path=${pdf}
    ...    output_path=${file_path}
    [Teardown]    Close All Pdfs

Embed the robot screenshot to the receipt PDF file Copy
    [Arguments]    ${order_number}    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    # Ensure a unique name
    # make "robot_preview_image" dir
    @{files}=    Create List
    ...    ${pdf}
    ...    ${screenshot}
    # Ensure a unique name
    ${file_name}=    Set Variable    0${order_number}_result.pdf
    RPA.FileSystem.Create Directory    ${OUTPUT_DIR}${/}result
    ${file_path}=    Set Variable    ${OUTPUT_DIR}${/}result${/}${file_name}
    # ! ValueError: Argument 'files' got value
    # Add Files To Pdf    @{files}    ${file_path} -> 에러 발생
    # 선언에서는 @, 참조에서는 $ ?
    Add Files To Pdf    ${files}    ${file_path}
    [Teardown]    Close All Pdfs

Order another Robot
    Click Button    id:order-another

Archive output PDFs
    [Documentation]    Create a ZIP file of receipt PDF files
    ${folder}=    Set Variable    ${OUTPUT_DIR}${/}result
    Archive Folder With Zip    ${folder}    ${OUTPUT_DIR}${/}result.zip

Close RobotSpareBin Browser
    Close Browser

Test keyword
    Fail    This keyword will fail

User Input task
    [Documentation]
    ...    사용자 인풋을 위한 Task
    Add Heading    Input from User    size=Large
    ${ex_url}=    Set Variable    https://robotsparebinindustries.com/#/robot-order
    Add Heading    ${ex_url}    size=Small
    Add Text Input    text_input    Please enter URL
    Add Submit Buttons    buttons=Submit,Cancel    default=Submit
    ${result}=    Run Dialog

    ${url}=    Set Variable    ${result}[text_input]
    Log To Console    ${url}

    RETURN    ${url}
