NAME		:= Zombie
NAME_DEBUG	:= $(NAME)_debug
CXX			:= c++
CXX_FLAGS	:= -Wall -Werror -Wextra -std=c++98 -MMD -MP

SRC_DIR		:= srcs
OBJ_DIR		:= obj

SRCS		:= main.cpp \
			   Zombie.cpp \
			   newZombie.cpp \
			   randomChump.cpp

# Debug config
ifeq ($(MAKECMDGOALS),debug)
	CXX_FLAGS	+= -g
	NAME		:= $(NAME_DEBUG)
	OBJ_DIR		:= $(OBJ_DIR)_debug
endif

OBJS		:= $(SRCS:%.cpp=$(OBJ_DIR)/%.o)
DEPS		:= $(OBJS:.o=.d)

# Rules
all	debug: $(NAME)

$(NAME): $(OBJS)
	$(CXX) $(CXX_FLAGS) $(OBJS) -o $(NAME)

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.cpp
	@mkdir -p $(OBJ_DIR)
	$(CXX) $(CXX_FLAGS) -I$(SRC_DIR) -c $< -o $@ 

-include $(DEPS)

clean:
	rm -rf obj obj_debug

fclean: clean
	rm -f $(NAME) $(NAME_DEBUG)

re: fclean all

.PHONY: all debug clean fclean re
