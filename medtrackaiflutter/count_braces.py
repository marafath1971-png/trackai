
import sys

def count_braces(filename):
    with open(filename, 'r') as f:
        content = f.read()
    
    open_brace = content.count('{')
    close_brace = content.count('}')
    open_paren = content.count('(')
    close_paren = content.count(')')
    open_bracket = content.count('[')
    close_bracket = content.count(']')
    
    print(f"Braces: {open_brace} vs {close_brace}")
    print(f"Parens: {open_paren} vs {close_paren}")
    print(f"Brackets: {open_bracket} vs {close_bracket}")

if __name__ == "__main__":
    count_braces(sys.argv[1])
