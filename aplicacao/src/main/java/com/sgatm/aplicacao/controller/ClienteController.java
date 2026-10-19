package com.sgatm_db.aplicacao.controller;

import com.sgatm_db.aplicacao.model.Cliente;
import com.sgatm_db.aplicacao.repository.ClienteRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

@Controller
public class ClienteController {

    @Autowired
    private ClienteRepository clienteRepository;

    // Lista os clientes e envia um objeto vazio para o formulário
    @GetMapping("/clientes")
    public String listarClientes(Model model) {
        model.addAttribute("clientes", clienteRepository.findAll());
        model.addAttribute("cliente", new Cliente());
        return "clientes";
    }

    @GetMapping("/clientes/editar/{id}")
    public String editarCliente(@PathVariable Long id, Model model) {
        Cliente cliente = clienteRepository.findById(id).orElse(null);
        model.addAttribute("cliente", cliente);
        model.addAttribute("clientes", clienteRepository.findAll());
        return "clientes";
    }

    // Recebe os dados do formulário e guarda na base de dados
    @PostMapping("/clientes")
    public String salvarCliente(@ModelAttribute Cliente cliente) {
        clienteRepository.save(cliente);
        return "redirect:/clientes";
    }

    // Deleta o cliente com tratamento de exceção (Integridade Referencial / B1)
    @GetMapping("/clientes/deletar/{id}")
    public String deletarCliente(@PathVariable("id") Long id, RedirectAttributes redirectAttributes) {
        try {
            clienteRepository.deleteById(id);
            redirectAttributes.addFlashAttribute("mensagemSucesso", "Cliente removido com sucesso!");
        } catch (org.springframework.dao.DataIntegrityViolationException e) {
            redirectAttributes.addFlashAttribute("mensagemErro", "Não é possível apagar este cliente pois ele possui equipamentos ou ordens de serviço vinculadas!");
        } catch (Exception e) {
            redirectAttributes.addFlashAttribute("mensagemErro", "Ocorreu um erro ao tentar excluir o cliente.");
        }
        return "redirect:/clientes";
}
}