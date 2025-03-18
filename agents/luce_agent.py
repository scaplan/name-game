import random
from agents.agent import Agent
# from agent import Agent




class Luce_Agent(Agent):
	def __init__(self, num, memlimit, initnamesdist, poprule, updaterule):
		super().__init__(num, memlimit, initnamesdist, poprule, updaterule)



	def __str__(self):
		return self.__class__.__name__ + " " + super().__str__() + " DETSTATE: " + str(self.in_deterministic_state())


	def in_deterministic_state(self):
		if len(self.memory) == 0:
			return False
		count_list = list(Counter(self.memory).items())
		if len(count_list) == 1:
			return True
		else:
			return False


	def get_name(self):
		"""
		the agent samples a choice randomly from the queue following Luce’s Choice Axiom
		(i.e., they select names probabilistically as a function of each name's frequency in the agent’s memory)
		"""
		if len(self.memory) > 0:
			return self.get_random_name()
		else:
			return self.sample_initial_names_distro()


