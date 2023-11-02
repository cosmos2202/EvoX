// Copyright (c) 2014-2018 Zano Project
// Copyright (c) 2014-2018 The Louisdor Project
// Distributed under the MIT/X11 software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#include "genesis.h"

namespace currency
{
#ifndef TESTNET
const genesis_tx_raw_data ggenesis_tx_raw = {{
0xd5a0800200000101,0x4b030afdfcd68a99,0x6dd8073be62ec9f0,0x3ba540fdeb1948bf,0x1aefc558b967420d,0x00e5de52df595615,0xfdfcf397bee9c080,0x3a2163137592030a,0xab9fcfcf42bf82e5,0x3a85df8369d00b77,0xd39bb3ad407af8a4,0x4f1664160600cd9e,0xf5d81eac3b5f178f,0x639994f69dbbed5e,0x2e92696c2c0d5a2d,0x322813d7abd3081f,0x4632363946364345,0x3938303634443343,0x3545464543324337,0x4141373930334431,0x1542303030433636,0x4f020b3e1e020b00},
{0xee,0x0e,0x0a,0x00,0x00}};
#else
  const genesis_tx_raw_data ggenesis_tx_raw = {{
      0xd5a0800200000101,0x4b030afdfcd68a99,0x6dd8073be62ec9f0,0x3ba540fdeb1948bf,0x1aefc558b967420d,0x00e5de52df595615,0xfdfcf397bee9c080,0x3a2163137592030a,0xab9fcfcf42bf82e5,0x3a85df8369d00b77,0xd39bb3ad407af8a4,0x4f1664160600cd9e,0xf5d81eac3b5f178f,0x639994f69dbbed5e,0x2e92696c2c0d5a2d,0x322813d7abd3081f,0x4632363946364345,0x3938303634443343,0x3545464543324337,0x4141373930334431,0x1542303030433636,0x4f020b3e1e020b00},
{0xee,0x0e,0x0a,0x00,0x00}}
#endif
}