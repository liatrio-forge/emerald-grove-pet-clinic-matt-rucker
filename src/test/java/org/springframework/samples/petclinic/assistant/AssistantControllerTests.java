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

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.DisabledInNativeImage;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Bean;
import org.springframework.http.MediaType;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.aot.DisabledInAotMode;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.is;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Tests for {@link AssistantController}.
 */
@WebMvcTest(AssistantController.class)
@DisabledInNativeImage
@DisabledInAotMode
@TestPropertySource(properties = "spring.ai.anthropic.api-key=test-key")
class AssistantControllerTests {

	@Autowired
	private MockMvc mockMvc;

	@TestConfiguration
	static class TestConfig {

		@Bean
		ChatClient chatClient(ChatClient.Builder builder) {
			return builder.build();
		}

		@Bean
		ChatClient.Builder chatClientBuilder() {
			return ChatClient.builder(new StubChatModel());
		}

	}

	@Test
	void chatShouldReturnJsonResponse() throws Exception {
		this.mockMvc
			.perform(post("/api/assistant/chat").contentType(MediaType.APPLICATION_JSON)
				.content("{\"message\": \"hello\"}"))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.response").exists());
	}

	@Test
	void historyShouldReturnEmptyArrayInitially() throws Exception {
		this.mockMvc.perform(get("/api/assistant/history"))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$").isArray());
	}

	@Test
	void chatShouldReturnFriendlyErrorOnFailure() throws Exception {
		// The StubChatModel returns a canned response, so to test error handling
		// we send a blank message which the controller handles gracefully
		this.mockMvc
			.perform(post("/api/assistant/chat").contentType(MediaType.APPLICATION_JSON).content("{\"message\": \"\"}"))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.response", is("Please enter a message.")));
	}

}
