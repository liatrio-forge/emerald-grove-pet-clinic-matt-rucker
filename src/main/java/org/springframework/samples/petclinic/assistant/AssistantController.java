/*
 * Copyright 2012-2025 the original author or authors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.springframework.samples.petclinic.assistant;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.chat.messages.AssistantMessage;
import org.springframework.ai.chat.messages.Message;
import org.springframework.ai.chat.messages.UserMessage;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import jakarta.servlet.http.HttpSession;

/**
 * REST controller for the AI assistant chat endpoints. Only active when an Anthropic API
 * key is configured.
 */
@RestController
@RequestMapping("/api/assistant")
@ConditionalOnProperty(name = "spring.ai.anthropic.api-key", matchIfMissing = false)
public class AssistantController {

	private static final int MAX_HISTORY_SIZE = 20;

	private final ChatClient chatClient;

	private final Map<String, List<Message>> conversations = new ConcurrentHashMap<>();

	public AssistantController(ChatClient chatClient) {
		this.chatClient = chatClient;
	}

	@PostMapping("/chat")
	public Map<String, String> chat(@RequestBody Map<String, String> request, HttpSession session) {
		String userMessage = request.get("message");
		if (userMessage == null || userMessage.isBlank()) {
			return Map.of("response", "Please enter a message.");
		}

		List<Message> history = this.conversations.computeIfAbsent(session.getId(), k -> new ArrayList<>());
		history.add(new UserMessage(userMessage));

		try {
			String response = this.chatClient.prompt(new Prompt(history)).call().content();
			history.add(new AssistantMessage(response));
			trimHistory(history);
			return Map.of("response", response);
		}
		catch (Exception ex) {
			history.remove(history.size() - 1);
			return Map.of("response",
					"I'm sorry, I'm having trouble processing your request right now. Please try again.");
		}
	}

	@GetMapping("/history")
	public List<Map<String, String>> history(HttpSession session) {
		List<Message> history = this.conversations.getOrDefault(session.getId(), List.of());
		return history.stream().map(msg -> {
			String role = (msg instanceof UserMessage) ? "user" : "assistant";
			return Map.of("role", role, "content", msg.getText());
		}).toList();
	}

	private void trimHistory(List<Message> history) {
		while (history.size() > MAX_HISTORY_SIZE) {
			history.remove(0);
		}
	}

}
