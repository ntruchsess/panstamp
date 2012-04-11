from api import TimeAPI as clock, NetworkAPI as network, CloudAPI as cloud

class WebScripts:
    @staticmethod
    def evn_00000001():
        """
        Switch main lights off
        """
        if False:
            pass
        elif clock.event and clock.time() == clock.sunrise():
            pass
        else:
            return            
        if not (clock.month() > 10):
            return
        if not (clock.month() < 03):
            return
        network.set_value("SWAP-network.SWAP.Binary 6", "OFF")

    @staticmethod
    def evn_00000002():
        """
        My 2nd event
        """
        if False:
            pass
        elif network.event[0] == "SWAP-network.garden.temp" and network.event[1] < 17.5:
            pass
        else:
            return
        pass

    @staticmethod
    def evn_00000003():
        """
        My 3rd event
        """
        if False:
            pass
        elif clock.event and clock.time() == clock.repeat_time(0000, 20):
            pass
        else:
            return
        cloud.push_pachube("SWAP-network.SWAP.Temperature", "cykPX_p0wDMmAm8VDXXel3lqv8-SAKx4UlFJT3lyYWhSND0g", "54081", "10.12.0")
        cloud.push_thinkspeak("SWAP-network.SWAP.Temperature", "VTPX8MN9BFZ7M8MZ", "field1")
