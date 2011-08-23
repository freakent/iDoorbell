#ifndef __PROWL_H__
#define __PROWL_H__

//char apikey[] = "abcdefghijklmnopqrstuvwxyz01234567890abc";
unsigned long deactivationInterval = 60000; // 1 minute
char application[] = "iDoorbell";

char apikeyParam[] = "apikey=";
char applicationParam[] = "&application=";
char eventParam[] = "&event=";
char descriptionParam[] = "&description=";

//Remember to re-calculate this if you change any of the text fields above 
unsigned int fixedContentLength = 89; 

char server[] = "api.prowlapp.com";
unsigned int port = 80;
char path[] = "/publicapi/add";

#endif

