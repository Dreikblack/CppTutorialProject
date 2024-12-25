#include "UltraEngine.h"
 
namespace UltraEngine
{
    void GetPassword(String& s)
    {
        s.resize(64);
        auto buffer = CreateStaticBuffer(s.Data(), s.size());
		buffer->PokeByte(29, 'o');
		buffer->PokeByte(25, '1');
		buffer->PokeByte(22, 'T');
		buffer->PokeByte(30, '4');
		buffer->PokeByte(35, 'M');
		buffer->PokeByte(14, 'd');
		buffer->PokeByte(24, 'e');
		buffer->PokeByte(19, ')');
		buffer->PokeByte(11, 'T');
		buffer->PokeByte(53, 'E');
		buffer->PokeByte(2, 'J');
		buffer->PokeByte(4, '<');
		buffer->PokeByte(45, 't');
		buffer->PokeByte(32, 'S');
		buffer->PokeByte(63, '0');
		buffer->PokeByte(26, 'v');
		buffer->PokeByte(46, '>');
		buffer->PokeByte(50, '@');
		buffer->PokeByte(16, 'C');
		buffer->PokeByte(21, 'm');
		buffer->PokeByte(10, 'E');
		buffer->PokeByte(59, 't');
		buffer->PokeByte(42, 'T');
		buffer->PokeByte(34, 'q');
		buffer->PokeByte(23, 'V');
		buffer->PokeByte(44, 'o');
		buffer->PokeByte(13, 'O');
		buffer->PokeByte(40, ':');
		buffer->PokeByte(48, 'n');
		buffer->PokeByte(56, 'K');
		buffer->PokeByte(36, 'c');
		buffer->PokeByte(52, '7');
		buffer->PokeByte(20, 'a');
		buffer->PokeByte(43, 'A');
		buffer->PokeByte(7, 'j');
		buffer->PokeByte(37, '{');
		buffer->PokeByte(55, 'v');
		buffer->PokeByte(33, 'f');
		buffer->PokeByte(6, '8');
		buffer->PokeByte(60, 'W');
		buffer->PokeByte(41, '.');
		buffer->PokeByte(38, 'o');
		buffer->PokeByte(62, '_');
		buffer->PokeByte(9, '9');
		buffer->PokeByte(1, '>');
		buffer->PokeByte(8, '_');
		buffer->PokeByte(15, 'Q');
		buffer->PokeByte(27, 'R');
		buffer->PokeByte(18, 'M');
		buffer->PokeByte(49, 'c');
		buffer->PokeByte(58, ';');
		buffer->PokeByte(0, '6');
		buffer->PokeByte(61, '3');
		buffer->PokeByte(47, 'H');
		buffer->PokeByte(17, 'q');
		buffer->PokeByte(57, '?');
		buffer->PokeByte(28, 'e');
		buffer->PokeByte(31, 'R');
		buffer->PokeByte(54, '|');
		buffer->PokeByte(3, 'O');
		buffer->PokeByte(51, '!');
		buffer->PokeByte(5, ')');
		buffer->PokeByte(39, 's');
		buffer->PokeByte(12, 'c');

#ifdef _DEBUG
        //Only uncomment this for testing
        //Assert(s == "6>JO<)8j_9ETcOdQCqM)amTVe1vReo4RSfqMc{os:.TAot>Hnc@!7E|vK?;tW3_0");
#endif
    }
}