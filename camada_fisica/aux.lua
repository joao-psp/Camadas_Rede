--- Client Side

function dec_to_8_bits(num,bits)
    -- returns a string with the 8 bits of the number
    local t = {} -- will contain the bits
    for b = bits, 1, -1 do
        t[b] = math.fmod(num, 2)
        num = math.floor((num - t[b]) / 2)
    end
    return table.concat(t)
end

function string_to_bits(str)
  -- returns a string with the 8 bit version of letters concatenated
  local i
  local ascii_value
  local result = {}
  for i=1, string.len(str) do
    ascii_value = string.byte(str, i)
    result[i] = dec_to_8_bits(ascii_value,8)
  end
  return table.concat(result)
end

function split_string(str, size)
  -- Split a string into mini strings of size size, end return an array of them
  local i=1
  local j=1
  local finish = false
  local result = {}
  local substr
  repeat
    substr = string.sub(str, i, i+size-1)
    -- Critério para parar
    if(string.len(substr) == 0) then
      break
    end
    -- No caso de a última substring ser menor que o tamanho, completa com 0
    if(string.len(substr) < size) then
      while(string.len(substr) < size) do
        substr = substr .. "0"
      end
      result[j] = substr
	  break
    end
    -- Concatena
    result[j] = substr
    i = i+size
    j = j+1
  until false
  return result
end

-- Server Side

function bits_to_char(bits)
  -- Convert an 8 bit number to a char
  local i, bit
  local result = 0
  local exp = 7
  for i=1,8 do
    bit = string.sub(bits, i, i)
    bit = tonumber(bit)
    if(bit == 1) then
      result = result + 2^exp
    end
    exp = exp - 1
  end
  return string.char(result)
end

function bits_to_string(bits)
  -- Convert a string of 8 bit numbers in chars
  local i=1
  local j=1
  local result = {}
  while i<string.len(bits) do
    ascii_bits = string.sub(bits, i, i+7)
    result[j] = bits_to_char(ascii_bits)
    i = i + 8
    j = j + 1
  end
  return table.concat(result)
end
