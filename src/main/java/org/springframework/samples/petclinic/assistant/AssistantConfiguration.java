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

import org.springframework.ai.chat.client.ChatClient;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Configuration for the AI assistant. Only active when an Anthropic API key is
 * configured.
 */
@Configuration
@ConditionalOnProperty(name = "spring.ai.anthropic.api-key", matchIfMissing = false)
public class AssistantConfiguration {

	@Bean
	ChatClient chatClient(ChatClient.Builder builder, AssistantTools tools) {
		return builder.defaultSystem("""
				You are the Emerald Grove Veterinary Clinic assistant. You help pet owners
				manage their accounts, pets, and visits. You can search for owners, view
				details, create new owners, add pets, book visits, and look up veterinarians.

				Guidelines:
				- ALWAYS confirm with the user before creating or modifying any data.
				  Describe what you are about to do and ask "Should I proceed?" before
				  calling any tool that creates an owner, adds a pet, or books a visit.
				- When presenting owner details, include the link to their details page.
				- Present information in a clear, organized format.
				- Dates must be in yyyy-MM-dd format.
				- Telephone numbers must be exactly 10 digits (US format, no dashes).
				- If you are unsure about something, ask for clarification.
				- Be friendly, concise, and helpful.
				""").defaultTools(tools).build();
	}

}
