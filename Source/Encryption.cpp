#include "Leadwerks.h"

namespace Leadwerks {
	void GetPassword(String& s) {
		s.resize(64);
		auto buffer = CreateStaticBuffer(s.Data(), s.size());
		buffer->PokeByte(18, 't');
		buffer->PokeByte(10, 'O');
		buffer->PokeByte(4, '2');
		buffer->PokeByte(25, 'm');
		buffer->PokeByte(61, 'm');
		buffer->PokeByte(52, '*');
		buffer->PokeByte(3, 'y');
		buffer->PokeByte(47, '6');
		buffer->PokeByte(11, '5');
		buffer->PokeByte(26, 'w');
		buffer->PokeByte(15, 'x');
		buffer->PokeByte(32, 'y');
		buffer->PokeByte(17, 'Y');
		buffer->PokeByte(40, 'K');
		buffer->PokeByte(41, '>');
		buffer->PokeByte(35, 'Z');
		buffer->PokeByte(29, ';');
		buffer->PokeByte(16, 'J');
		buffer->PokeByte(22, 'f');
		buffer->PokeByte(24, 'v');
		buffer->PokeByte(42, '<');
		buffer->PokeByte(63, '_');
		buffer->PokeByte(54, 'O');
		buffer->PokeByte(48, 'n');
		buffer->PokeByte(14, 'd');
		buffer->PokeByte(30, 'I');
		buffer->PokeByte(8, 'y');
		buffer->PokeByte(43, '.');
		buffer->PokeByte(27, '5');
		buffer->PokeByte(2, '&');
		buffer->PokeByte(45, 'D');
		buffer->PokeByte(38, 'a');
		buffer->PokeByte(21, 'A');
		buffer->PokeByte(28, ']');
		buffer->PokeByte(19, ':');
		buffer->PokeByte(56, '-');
		buffer->PokeByte(55, 'L');
		buffer->PokeByte(7, '&');
		buffer->PokeByte(9, '|');
		buffer->PokeByte(34, 'S');
		buffer->PokeByte(44, '@');
		buffer->PokeByte(59, 'i');
		buffer->PokeByte(62, 'e');
		buffer->PokeByte(23, 'E');
		buffer->PokeByte(39, ',');
		buffer->PokeByte(51, 'l');
		buffer->PokeByte(13, 'r');
		buffer->PokeByte(50, 'e');
		buffer->PokeByte(0, 'U');
		buffer->PokeByte(6, '.');
		buffer->PokeByte(49, 'l');
		buffer->PokeByte(20, '#');
		buffer->PokeByte(53, 'P');
		buffer->PokeByte(36, '-');
		buffer->PokeByte(57, '_');
		buffer->PokeByte(33, 'l');
		buffer->PokeByte(46, '[');
		buffer->PokeByte(12, 'c');
		buffer->PokeByte(58, 'i');
		buffer->PokeByte(37, 'm');
		buffer->PokeByte(5, '#');
		buffer->PokeByte(1, 'F');
		buffer->PokeByte(31, 'U');
		buffer->PokeByte(60, 'W');

#ifdef _DEBUG
		//Only uncomment this for testing
		//Assert(s == "UF&y2#.&y|O5crdxJYt:#AfEvmw5];IUylSZ-ma,K><.@D[6nlel*POL-_iiWme_");
#endif
	}
}