import numpy as np
from math import log
import random
from collections import Counter
from agents.agent import Agent

class TP_Agent(Agent):
	def __init__(self, num, memlimit, initnamesdist, poprule, updaterule):
		super().__init__(num, memlimit, initnamesdist, poprule, updaterule)
		self.hasprodname = False
		self.prodname = ""
		# calculate productivity threshold
		EXCEPTION_THRESHOLD = (self.MEM_SIZE/np.log(self.MEM_SIZE))
		self.PRODUCTIVITY_THRESHOLD = self.MEM_SIZE - EXCEPTION_THRESHOLD



	def __str__(self):
		return self.__class__.__name__ + " "+ super().__str__() + " DETSTATE: " + str(self.in_deterministic_state()) + " " + str(Counter(self.memory))


	def prob_sample_name(self):
		if len(self.memory) == 0:
			return self.sample_initial_names_distro()
		else:
			return random.choice(self.memory)


	def get_name(self):
		if self.hasprodname:
			return self.prodname
		else:
			return self.prob_sample_name()


	def in_deterministic_state(self):
		if self.roundsplayed > 0 and self.hasprodname:
			return True
		else:
			return False


	def compare_add_name(self, yourName, theirName):
		super().compare_add_name(yourName, theirName)
		# every time a word gets added to memory check if now self.hasprodname should be set to True or False
		self.check_productivity()


	def check_productivity(self):
		c = Counter(self.memory)
		most_frequent_tuple = c.most_common()[0]
		most_frequent_type = most_frequent_tuple[0]
		most_frequent_token_count = most_frequent_tuple[1]
		# print("Need: ", self.PRODUCTIVITY_THRESHOLD, " and got: ", most_frequent_token_count)
		if most_frequent_token_count >= self.PRODUCTIVITY_THRESHOLD:
			self.hasprodname = True
			self.prodname = most_frequent_type
			return (1, most_frequent_type)
		else:
			self.hasprodname = False
			self.prodname = ""
			return (0, most_frequent_type)

	def bizarro_world_check_prod(self, thresh_to_check):
		"""
		for comparison, check whether the current agent has a productive name
		based on a "bizarro world" non-TP threshold
		"""
		if self.roundsplayed == 0:
			return False
		# else at least one...

		c = Counter(self.memory)
		most_frequent_tuple = c.most_common()[0]
		most_frequent_type = most_frequent_tuple[0]
		most_frequent_token_count = most_frequent_tuple[1]
		if most_frequent_token_count >= thresh_to_check:
			return True
		else:
			return False


