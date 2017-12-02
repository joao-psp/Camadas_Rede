# Client side
def to_16_bits(number):
    # Convert an into a 16 bit st
    binary = bin(number)[2:]
    while(len(binary) < 16):
        binary = "0" + binary
    return binary


def to_32_bits(number):
    # Convert an into a 32 bit st
    binary = bin(number)[2:]
    while(len(binary) < 32):
        binary = "0" + binary
    return binary

def to_4_bits(number):
    # Convert an into a 4 bit st
    binary = bin(number)[2:]
    while(len(binary) < 4):
        binary = "0" + binary
    return binary

def to_6_bits(number):
    # Convert an into a 6 bit st
    binary = bin(number)[2:]
    while(len(binary) < 6):
        binary = "0" + binary
    return binary

def to_1_bit(number):
    # Convert an into a 1 bit str
    binary = bin(number)[2:]
    return binary

def to_8_bits(number):
    # Convert an into a 8 bit str
    binary = bin(number)[2:]
    while(len(binary) < 8):
        binary = "0" + binary
    return binary

def to_24_bits(number):
    # Convert an into a 24 bit st
    binary = bin(number)[2:]
    while(len(binary) < 24):
        binary = "0" + binary
    return binary

def unmount_tcp_segment(segment):
    dict_segment = {
        'src_port' : segment[0:15],
        'dest_port' : segment[16:31],
        'seq_number' : segment[32:63],
        'ack_number' : segment[64:95],
        'data_offset' : segment[96:99],
        'reserved' : segment[100:105],
        'urg' : segment[106],
        'ack' : segment[107],
        'psh' : segment[108],
        'rst' : segment[109],
        'syn' : segment[110],
        'fin' : segment[111],
        'window' : segment[112:127],
        'checksum' : segment[128:143],
        'urgent_pointer' : segment[144:159],
        'options' :  segment[160:183],
        'padding' : segment[184:191],
        'payload' : segment[192:]
     }
    return dict_segment
