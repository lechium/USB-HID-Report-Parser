
/* HID 1.11: https://www.usb.org/document-library/device-class-definition-hid-11
** HID Usage Tables 1.12: https://www.usb.org/document-library/hid-usage-tables-112
*/

#if defined(_WIN32) || defined(_WIN64)
#pragma warning(disable:4996)
#endif

#include <stdio.h>
#include <string.h>

#include "report_item.h"
#include "report_usage.h"

#define ri_StringGet        sprintf

#define ri_ItemSize(sizeMask)      ((uint8_t)(sizeMask) == Size_4B?4:(uint8_t)(sizeMask))

mint8_t *ri_ColletionType(uint8_t itemData)
{
    static mint8_t *colType[] = {
        "Physical",
        "App",
        "Logical",
        "Report",
        "Named Array",
        "Usage Switch",
        "Usage Modifier"
    };

    if(itemData <= Col_Usage_Modifier)
        return colType[itemData];

    /* 0x07-0x7F RFU.
    ** 0x80-0xFF Vendor defined.
    */
    return "Vendor Defined";
}

mint8_t *ri_dataType(uint8_t itemTag, int32_t itemData)
{
#define STR_BUFFER_SIZE     (128U)
    static mint8_t str[STR_BUFFER_SIZE];

    int32_t index = 0;

    memset(str, 0, STR_BUFFER_SIZE);
    /* Only data byte 0 is used now. */
    index += ri_StringGet(str + index, "%s", (itemData & Constant)?"Cnst":"Data");
    index += ri_StringGet(str + index, "%s", (itemData & Variable)?", Var":", Array");
    index += ri_StringGet(str + index, "%s", (itemData & Relative)?", Rel":", Abs");
    if(itemData & Wrap)
        index += ri_StringGet(str + index, ", Wrap");
    if(itemData & NonLinear)
        index += ri_StringGet(str + index, ", NonLinear");
    if(itemData & No_Prefered)
        index += ri_StringGet(str + index, ", No Preferred");
    if(itemData & Null_State)
        index += ri_StringGet(str + index, ", Null State");

    /* Input Items Data bit 7 is undefined and is RFU. */
    if((itemTag & TAG_MASK) != Input(0) && (itemData & Volatile))
        index += ri_StringGet(str + index, ", Volatile");

    /* Data byte 1~3 is RFU. */
    if(itemData & 0xFFFFFF00)
        index += ri_StringGet(str + index, ", ???");

    str[index] = 0;
    return (mint8_t *)str;
}

void  ri_MainItem(uint8_t itemTag, int32_t itemData, uint8_t *pspace)
{
    mint8_t str[256] = {0};
    int32_t index = 0;

    for (; index < *pspace; index++)
        str[index] = ' ';

    switch(itemTag)
    {
    case Input(0):
        index += ri_StringGet(str + index, "  Input (%s)", ri_dataType(Input(0), itemData));
        break;
    case Output(0):
        index += ri_StringGet(str + index, "  Output (%s)", ri_dataType(Output(0), itemData));
        break;
    case Feature(0):
        index += ri_StringGet(str + index, "  Feature (%s)", ri_dataType(Feature(0), itemData));
        break;
    case Collection(0):
        *pspace += 2;
        index += ri_StringGet(str + index, "Collection (%s)", ri_ColletionType((uint8_t)itemData));
        if(itemData & 0xFFFFFF00U)
            index += ri_StringGet(str + index, " ???");
        break;
    case End_Colletion(0):
        *pspace -= 2;
        index -= 2;
        index += ri_StringGet(str + index, "End Collection");
        break;
    default:
        index += ri_StringGet(str + index, "Vendor Defined Item: %02X", itemTag);
        break;
    }
    LOG("%s\r\n", str);
}

mint8_t *ri_UsagePage(int32_t itemData)
{
    switch(itemData)
    {
    case UP_Generic_Desktop:
        return "Generic Desktop";
    case UP_Simulation_Controls:
        return "Simulation";
    case UP_VR_Controls:
        return "VR Controls";
    case UP_Sport_Controls:
        return "Sport Controls";
    case UP_Game_Controls:
        return "Game Controls";
    case UP_Generic_Device_Controls:
        return "Generic Device";
    case UP_Keyboard_or_Keypad:
        return "Keyboard";
    case UP_LEDs:
        return "LEDs";
    case UP_Button:
        return "Buttons";
    case UP_Ordinal:
        return "Ordinal";
    case UP_Telephony:
        return "Telephony";
    case UP_Consumer:
        return "Consumer";
    case UP_Digitizer:
        return "Digitizer";
    case UP_PID_Page:
        return "PID Page";
    case UP_Unicode:
        return "Unicode";
    case UP_Alphanumeric_Display:
        return "Alphanumeric Display";
    case UP_Medical_Instruments:
        return "Medical Instruments";
    case UP_Monitor_pages_1:
    case UP_Monitor_pages_2:
    case UP_Monitor_pages_3:
    case UP_Monitor_pages_4:
        return "Monitor";
    case UP_Power_pages_1:
    case UP_Power_pages_2:
    case UP_Power_pages_3:
    case UP_Power_pages_4:
        return "Power";
    case UP_Bar_Code_Scanner_page:
        return "Bar Code Scanner";
    case UP_Scale_page:
        return "Scale";
    case UP_MSR_Devices:
        return "MSR Device";
    case UP_Camera_Control_Page:
        return "Camera";
    case UP_Arcade_Page:
        return "Arcade";
    default:
        return "Vendor Defined";
    }
}

uint32_t ri_GetItemData(uint8_t *itemData, uint8_t size)
{
    if(size == 1)
        return *itemData;
    else if(size == 2)
        return *((uint16_t *)itemData);
    else if(size == 4)
        return *((uint32_t *)itemData);

    return 0;
}

mint8_t *ri_Exponent(int32_t itemData)
{
    static mint8_t *str[] = {"5","6","7","-8","-7","-6","-5","-4","-3","-2","-1"};

    uint8_t code = (uint8_t)itemData;

    if(code < 0x10U && code > 0x04U)
        return str[code - 5];

    return "Vendor Defined";
}

#define NibbleToByte(nibble)    (((mint8_t)nibble & 0x08)?((mint8_t)nibble | 0xF0):(mint8_t)nibble)

mint8_t *ri_Unit(uint32_t itemData)
{
    static mint8_t str[128] = {0};

    mint8_t *strUnit_SI_Linear[] = {"SI Linear","cm","Gram","Seconds","Kelvin","Ampere","Candela"};
    mint8_t *strUnit_SI_Rotation[] = {"SI Rotation","rad","Gram","Seconds","Kelvin","Ampere","Candela"};
    mint8_t *strUnit_English_Linear[] = {"English Linear","Inch","Slug","Seconds","Fahrenheit","Ampere","Candela"};
    mint8_t *strUnit_English_Rotation[] = {"English Rotation","Degrees","Slug","Seconds","Fahrenheit","Ampere","Candela"};
    mint8_t **strUnit = NULL;

    int32_t index = 0;
    mint8_t nibble = itemData & 0xF;
    mint8_t nibbleNo = 0;    /* 7 is reserved. */

    /* System */
    switch(nibble)
    {
    case System_None:
        return "None";
    case System_SI_Linear:
        strUnit = strUnit_SI_Linear;
        break;
    case System_SI_Rotation:
        strUnit = strUnit_SI_Rotation;
        break;
    case System_English_Linear:
        strUnit = strUnit_English_Linear;
        break;
    case System_English_Rotation:
        strUnit = strUnit_English_Rotation;
        break;
    default:
        return "Vendor Defined";
    }

    index = ri_StringGet(str + index, "%s:", strUnit[0]);
    itemData >>= 4; /* 跳过首个nibble */
    nibbleNo++;

    for(; itemData && nibbleNo < 7; itemData >>= 4)
    {
        nibble = itemData & 0xF;
        if(nibble)
            index += ri_StringGet(str + index, " %s[%d]", strUnit[nibbleNo], NibbleToByte(nibble));
        nibbleNo++;
    }

    return str;
}

void ri_GlobalItem(uint8_t itemTag, uint32_t itemData, uint8_t space, int32_t *pUsagePage)
{
    mint8_t str[256] = {0};
    int32_t index = 0;

    for (; index < space; index++)
        str[index] = ' ';

    switch(itemTag)
    {
    case Usage_Page(0):
        *pUsagePage = itemData;
        index += ri_StringGet(str + index, "Usage Page (%s)", ri_UsagePage(itemData));
        break;
    case Logical_Minimum(0):
            if (itemData == 0x81){
                itemData = -127;
            }
        index += ri_StringGet(str + index, "Logical Min (%i)", itemData);
        break;
    case Logical_Maximum(0):
        index += ri_StringGet(str + index, "Logical Max (%d)", itemData);
        break;
    case Physical_Minimum(0):
            if (itemData == 0x81){
                itemData = -127;
            }
        index += ri_StringGet(str + index, "Physical Min (%i)", itemData);
        break;
    case Physical_Maximum(0):
        index += ri_StringGet(str + index, "Physical Max (%d)", itemData);
        break;
    case Unit_Exponent(0):
        index += ri_StringGet(str + index, "Unit Exponent (%s)", ri_Exponent(itemData));
        break;
    case Unit(0):
        index += ri_StringGet(str + index, "Unit (%s)", ri_Unit((uint32_t)itemData));
        break;
    case Report_Size(0):
        index += ri_StringGet(str + index, "Report Size (%d)", itemData);
        break;
    case Report_ID(0):
        index += ri_StringGet(str + index, "Report ID (%d)", itemData);
        break;
    case Report_Count(0):
        index += ri_StringGet(str + index, "Report Count (%d)", itemData);
        break;
    case Push(0):
        index += ri_StringGet(str + index, "Push");
        break;
    case Pop(0):
        index += ri_StringGet(str + index, "Pop");
        break;
    default:
        index += ri_StringGet(str + index, "Vendor Defined Item: %02X", itemTag);
        break;
    }

    LOG("%s\r\n", str);
}

#define ri_DelimiterItem(itemData)  (((int32_t)itemData)? \
                                     (((int32_t)itemData == 1)?"Open Set":"Vendor Defined Setting"): \
                                     "Close Set")

void ri_LocalItem(uint8_t itemTag, int32_t itemData, uint8_t space, int32_t usagePage)
{
    mint8_t str[256] = {0};
    int32_t index = 0;

    for (; index < space; index++)
        str[index] = ' ';

    switch(itemTag)
    {
    case Usage(0):
        /* TODO: 根据Usage Page查表 */
        index += ri_StringGet(str + index, "Usage (%s)", ri_Usage(usagePage, itemData));
        break;
    case Usage_Minimum(0):
        index += ri_StringGet(str + index, "Usage Min (%d)", itemData);
        break;
    case Usage_Maximum(0):
        index += ri_StringGet(str + index, "Usage Max (%d)", itemData);
        break;
    case Designator_Index(0):
        index += ri_StringGet(str + index, "Designator Index (%d)", itemData);
        break;
    case Designator_Minimum(0):
        index += ri_StringGet(str + index, "Designator Min (%d)", itemData);
        break;
    case Designator_Maximum(0):
        index += ri_StringGet(str + index, "Designator Max (%d)", itemData);
        break;
    case String_Index(0):
        index += ri_StringGet(str + index, "String Index (%d)", itemData);
        break;
    case String_Minimum(0):
        index += ri_StringGet(str + index, "String Min (%d)", itemData);
        break;
    case String_Maximum(0):
        index += ri_StringGet(str + index, "String Max (%d)", itemData);
        break;
    case Delimiter(0):
        /* defines the deginning or end of a set of local items. 
        ** 1 = open set, 0 = close set. 
        */
        index += ri_StringGet(str + index, "Delimiter (%s)", ri_DelimiterItem(itemData));
    default:
        index += ri_StringGet(str + index, "Vendor Defined Item: %02X", itemTag);
        break;
    }

    LOG("%s\r\n", str);
}

int ri_Parse(uint8_t *buf, uint16_t len)
{
    uint8_t space = 0;
    uint16_t index = 0;
    LOGD("Report Item Parse:\r\n");
    while(index < len)
    {
        static int32_t sUsagePage = -1;

        uint8_t itemTag = buf[index] & TAG_MASK;
        uint8_t itemSize = ri_ItemSize(buf[index] & SIZE_MASK);
        uint32_t itemData = 0;

        if(index + itemSize >= len)
        {
            LOGE("out of buffer.\r\n");
            break;
        }
        
        itemData = ri_GetItemData(&buf[index + 1], itemSize);
        switch(itemTag & TYPE_MASK)
        {
        case MAIN_ITEM:
            ri_MainItem(itemTag, itemData, &space);
            break;
        case GLOBAL_ITEM:
            ri_GlobalItem(itemTag, itemData, space, &sUsagePage);
            break;
        case LOCAL_ITEM:
            ri_LocalItem(itemTag, itemData, space, sUsagePage);
            break;
        default:
            LOG("Vendor Defined Type: %02X, index: %d\r\n", itemTag, index);
            break;
        }
        index += (itemSize + 1);
    }

    return (index < len);
}

char og_generic_desc[] = {
    0x05, 0x01, 0x09, 0x05, 0xa1, 0x01, 0x09, 0x05, 0xa1, 0x02, 0x15, 0x81,
    0x25, 0x7f, 0x35, 0x81, 0x45, 0x7f, 0x05, 0x01, 0x09, 0x01, 0xa1, 0x00,
    0x75, 0x08, 0x95, 0x04, 0x09, 0x30, 0x09, 0x31, 0x09, 0x32, 0x09, 0x35,
    0x81, 0x02, 0xc0, 0x95, 0x02, 0x15, 0x00, 0x26, 0xff, 0x00, 0x35, 0x00,
    0x46, 0xff, 0x00, 0x05, 0x09, 0x09, 0x07, 0x09, 0x08, 0x81, 0x02, 0x95,
    0x04, 0x05, 0x01, 0x09, 0x90, 0x09, 0x92, 0x09, 0x91, 0x09, 0x93, 0x81,
    0x02, 0x95, 0x06, 0x05, 0x09, 0x19, 0x01, 0x29, 0x06, 0x81, 0x02, 0x75,
    0x01, 0x95, 0x02, 0x15, 0x00, 0x25, 0x01, 0x35, 0x00, 0x45, 0x01, 0x09,
    0x09, 0x09, 0x0a, 0x81, 0x02, 0x95, 0x01, 0x05, 0x0c, 0x0a, 0x23, 0x02,
    0x81, 0x02, 0x95, 0x05, 0x81, 0x03, 0x95, 0x04, 0x05, 0x08, 0x1a, 0x00,
    0xff, 0x2a, 0x03, 0xff, 0x91, 0x02, 0x95, 0x04, 0x91, 0x01, 0xc0, 0xc0
};



int doScienceBro(unsigned char *data, size_t length)
{
    ri_Parse(data, length);
    return 0;
}
