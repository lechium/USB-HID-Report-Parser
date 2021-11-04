#include "report_item.h"
#import <Foundation/Foundation.h>
#include <stdio.h>
#include <errno.h>
#include <libgen.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <getopt.h>
#import <sys/utsname.h>
uint8_t USBD_KeyBoardReportDesc[] =
{
  /* 键盘定义了8B长度的消息：
  ** 第一个Byte表示8个特殊按键是否按下
  ** 第二个Byte为常量，自定义数据
  ** 后六个Byte代表普通按键是否被按下，最多同时识别六个，超出则应输出按键无效(FF)
  */
  0x05, 0x01,  /* Usage Page (Generic Desktop) */
  0x09, 0x06,  /* Usage (Keyboard) */
  0xA1, 0x01,  /* Collection (Application) */
  0x85, 0x01,  /* Report ID 只有一个报告，可以忽略该字段 */
  0x05, 0x07,  /*   Usage (Keypad) */

  /* 特殊按键的输入报告 */
  0x19, 0xE0,  /*   Usage Minimum (Left Control) */
  0x29, 0xE7,  /*   Usage Maximum (Right GUI) */
  0x15, 0x00,  /*   Logical Minimum (0) */
  0x25, 0x01,  /*   Logical Maximum (1) */
  0x95, 0x08,  /*   Report Count (8) */
  0x75, 0x01,  /*   Report Size Bit(s) (1) */
  0x81, 0x02,  /*     Input (Data, Var, Abs) 8bit分别对应E0~E7键值 */
  0x95, 0x01,  /*   Report Count (1) */
  0x75, 0x08,  /*   Report Size Bit(s) (8) */
  0x81, 0x03,  /*     Input (Const, Var, Abs) 固定为常量0，保留字节OEM使用 */

  /* 普通按键的输入报告 */
  0x05, 0x07,  /*   Usage (Keypad) */
  0x19, 0x00,  /*   Usage Minimum (0)：没有键按下 */
  0x29, 0x68,  /*   Usage Maximum (104)：最大键值 */
  0x15, 0x00,  /*   Logical Minimum (0) */
  0x25, 0x68,  /*   Logical Maximum (104) */
  0x95, 0x06,  /*   Report Count (6)：最多同时识别6个普通键按下 */
  0x75, 0x08,  /*   Report Size Bit(s) (8) */
  0x81, 0x00,  /*     Input (Data, Array, Abs) */
    
  /* 指示灯的输出报告 */
  0x05, 0x08,  /*   Usage (LEDs) */
  0x19, 0x01,  /*   Usage Minimum (NumLock) */
  0x29, 0x05,  /*   Usage Maximum (Kana)  */
  0x95, 0x05,  /*   Report Count (5) */
  0x75, 0x01,  /*   Report Size Bit(s) (1) */
  0x91, 0x02,  /*     Output (Data, Var, Abs) */
  0x95, 0x01,  /*   Report Count (1) */
  0x75, 0x03,  /*   Report Size Bit(s) (3) */
  0x91, 0x01,  /*     Output(Const, Array, Abs) 补充3bit对齐到Byte */
  0xC0         /* End Collection */
};

uint8_t generic_desc[] = {
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

char *progname;
char *path;

int main(int argc, const char * argv[]) {

        progname = basename((char*)argv[0]);
        path = dirname((char*)argv[0]);
	if (argc >=2){
		char *inputFile = (char*)argv[1];
		NSString *filePath = [NSString stringWithUTF8String:inputFile];
		NSLog(@"processing file: %@", filePath);
		NSData *data = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
		size_t length = [data length];
		uint8_t bytes[length];
		[data getBytes:bytes length:length];
		ri_Parse(bytes, length);
	} else {
		ri_Parse(generic_desc, sizeof(generic_desc));
	}
	return 0;
	
}

