import random
from agents.agent import Agent

##  Author: Spencer Caplan
##  CUNY Graduate Center


class Luce_Noise_Agent(Agent):
	def __init__(self, num, memlimit, initnamesdist, poprule, updaterule, noiseratio):
		super().__init__(num, memlimit, initnamesdist, poprule, updaterule)
		self.NOISYRATIO = noiseratio


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

		or, according to some *additional* noise parameter, they randomly produce something *other* than their initial choice
		"""
		if len(self.memory) > 0:
			first_choice = self.get_random_name()
			if self.NOISYRATIO < random.random():
				return first_choice
			else:
				second_choice_list = [x for x in self.memory if x != first_choice]
				# gotta account for empty backup if memory is fully saturated with first choice here..
				if len(second_choice_list):
					return random.choice(second_choice_list)
				else:
					return first_choice
		else:
			return self.sample_initial_names_distro()


