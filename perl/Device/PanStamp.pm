package Device::PanStamp;

use Device::PanStamp::SwapServer;
use Device::PanStamp::SwapInterface;

sub create_server($$) {
	my ($class,$interface,$settings);
	
	my $interface = Device::PanStamp::SwapInterface->new() unless defined $interface;
	
	return $interface->create_server();
}

1;

