//+------------------------------------------------------------------+
//| VolumeProfile.mqh — Include file for VolumeProfile
//| MetaTrader AI — Function Library
//| Version: v0.0.3
//+------------------------------------------------------------------+
#ifndef __VOLUMEPROFILE_MQH__
#define __VOLUMEPROFILE_MQH__

//+------------------------------------------------------------------+
//|                                       VolumeProfile.mq5         |
//|                              MetaTrader AI - Custom Indicators   |
//|          Ranks #5 — Volume at Price (Market Profile)             |
//+------------------------------------------------------------------+


//--- Indicator buffers
double         BufferVolume[];
double         BufferColor[];
double         g_pocPrice = 0;
double         g_vaHigh   = 0;
double         g_vaLow    = 0;


#endif // __VOLUMEPROFILE_MQH__
