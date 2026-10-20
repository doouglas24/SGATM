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
import jakarta.servlet.http.HttpSession;

@Controller
public class ClienteController {

    @Autowired
    private ClienteRepository clienteRepository;

    @GetMapping("/clientes")
    public String listarClientes(HttpSession session, Model model) {
        String cargo = (String) session.getAttribute("cargoUsuario");
        if (cargo == null) return "redirect:/login";
        if (!cargo.equals("Gerente") && !cargo.equals("Atendente")) {
            return "redirect:/?erro=Acesso Negado!";
        }

        model.addAttribute("clientes", clienteRepository.findAll());
        model.addAttribute("cliente", new Cliente());
        return "clientes";
    }

    @PostMapping("/clientes")
    public String salvarCliente(@ModelAttribute Cliente cliente, HttpSession session) {
        String cargo = (String) session.getAttribute("cargoUsuario");
        if (cargo == null || (!cargo.equals("Gerente") && !cargo.equals("Atendente"))) {
            return "redirect:/login";
        }
        clienteRepository.save(cliente);
        return "redirect:/clientes";
    }

    @GetMapping("/clientes/deletar/{id}")
    public String deletarCliente(@PathVariable Long id, HttpSession session) {
        String cargo = (String) session.getAttribute("cargoUsuario");
        // Apenas Gerente pode apagar registos críticos
        if (cargo == null || !cargo.equals("Gerente")) {
            return "redirect:/clientes?erro=Apenas o Gerente pode apagar clientes!";
        }
        clienteRepository.deleteById(id);
        return "redirect:/clientes";
    }

    @GetMapping("/clientes/editar/{id}")
    public String carregarEdicaoCliente(@PathVariable Long id, HttpSession session, Model model) {
        String cargo = (String) session.getAttribute("cargoUsuario");
        if (cargo == null || !cargo.equals("Gerente")) {
            return "redirect:/clientes?erro=Acesso Negado!";
        }
        Cliente cliente = clienteRepository.findById(id).orElse(null);
        model.addAttribute("cliente", cliente);
        model.addAttribute("clientes", clienteRepository.findAll());
        return "clientes";
    }
}