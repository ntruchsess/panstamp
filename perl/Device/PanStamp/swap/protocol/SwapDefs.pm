#########################################################################
# class SwapAddress
#
# SWAP reserved addresses
#########################################################################

package Device::PanStamp::swap::protocol::SwapAddress;

use strict;
use warnings;

use parent qw(Exporter);
our @EXPORT_OK = qw(BROADCAST_ADDR);    # symbols to export on request

## Broadcast address
use constant BROADCAST_ADDR => 0x00;

#########################################################################
# class SwapFunction:
#
# SWAP function codes
#########################################################################

package Device::PanStamp::swap::protocol::SwapFunction;

use strict;
use warnings;

use parent qw(Exporter);
our @EXPORT_OK = qw(STATUS QUERY COMMAND);    # symbols to export on request

use constant {
  ## SWAP STATUS type
  STATUS => 0x00,
  ## SWAP QUERY type
  QUERY => 0x01,
  ## SWAP COMMAND type
  COMMAND => 0x02
};

#########################################################################
# class SwapRegId
#
# Standard register ID's
#########################################################################

package Device::PanStamp::swap::protocol::SwapRegId;

use strict;
use warnings;

use parent qw(Exporter);
our @EXPORT_OK = qw(
  ID_PRODUCT_CODE
  ID_HW_VERSION
  ID_FW_VERSION
  ID_SYSTEM_STATE
  ID_FREQ_CHANNEL
  ID_SECU_OPTION
  ID_SECU_PASSWORD
  ID_SECU_NONCE
  ID_NETWORK_ID
  ID_DEVICE_ADDR
  ID_TX_INTERVAL
  );    # symbols to export on request

use constant {
  ID_PRODUCT_CODE  => 0,
  ID_HW_VERSION    => 1,
  ID_FW_VERSION    => 2,
  ID_SYSTEM_STATE  => 3,
  ID_FREQ_CHANNEL  => 4,
  ID_SECU_OPTION   => 5,
  ID_SECU_PASSWORD => 6,
  ID_SECU_NONCE    => 7,
  ID_NETWORK_ID    => 8,
  ID_DEVICE_ADDR   => 9,
  ID_TX_INTERVAL   => 10
};

#########################################################################
# class SwapState:
#
# System states
#########################################################################

package Device::PanStamp::swap::protocol::SwapState;

use strict;
use warnings;

use parent qw(Exporter);
@EXPORT_OK = qw(
  RESTART
  RXON
  RXOFF
  SYNC
  LOWBAT
  );    # symbols to export on request

use constant {
  RESTART => 0,
  RXON    => 1,
  RXOFF   => 2,
  SYNC    => 3,
  LOWBAT  => 4
};

#########################################################################
# sub toString
# Return string defining the system state
#
# @param state: SWAP state to be converted to string
#
# @return State in string format
#########################################################################

sub toString($) {
  my $state = shift;
TOSTRING: {
    $state eq RESTART and return "Device restarting";
    $state eq RXON    and return "RF reception enabled";
    $state eq RXOFF   and return "RF reception disabled";
    $state eq SYNC    and return "Synchronization mode";
    $state eq LOWBAT  and return "Device battery is low";
  }
  return $state;
}

#########################################################################
# class SwapType:
#
# Data types
#########################################################################

package Device::PanStamp::swap::protocol::SwapType;

use strict;
use warnings;

use parent qw(Exporter);
our @EXPORT_OK = qw(
  BINARY
  NUMBER
  STRING
  INPUT
  OUTPUT
  );    # symbols to export on request

use constant {
  BINARY => "bin",
  NUMBER => "num",
  STRING => "str",
  INPUT  => "inp",
  OUTPUT => "out"
};

#########################################################################
# sub toString(type):
#
# Return complete name of the type
#
# @param type: Type of parameter
#
# @return Type of parameter in string format
#########################################################################

sub toString($) {
  my $type = shift;

TOSTRING: {
    $type eq BINARY and return "binary";
    $type eq NUMBER and return "number";
    $type eq STRING and return "string";
    $type eq INPUT  and return "input";
    $type eq OUTPUT and return "output";
  }
}

1;
